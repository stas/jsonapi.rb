require 'securerandom'
require 'active_record'
require 'action_controller/railtie'
require 'jsonapi'
require 'ransack'

Rails.logger = Logger.new(STDOUT)
Rails.logger.level = ENV['LOG_LEVEL'] || Logger::WARN

JSONAPI::Rails.install!

ActiveRecord::Base.logger = Rails.logger
ActiveRecord::Base.establish_connection(
  ENV['DATABASE_URL'] || 'sqlite3::memory:'
)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :first_name
    t.string :last_name
    t.timestamps
  end

  create_table :notes, force: true do |t|
    t.string :title
    t.integer :user_id
    t.integer :quantity
    t.timestamps
  end
end

class User < ActiveRecord::Base
  has_many :notes
end

class Note < ActiveRecord::Base
  validates_format_of :title, without: /BAD_TITLE/
  belongs_to :user, required: true
end

class CustomNoteSerializer
  include FastJsonapi::ObjectSerializer

  set_type :note
  belongs_to :user
  attributes(:title, :created_at, :updated_at)
end

class UserSerializer
  include FastJsonapi::ObjectSerializer

  has_many :notes, serializer: CustomNoteSerializer
  attributes(:first_name, :last_name, :created_at, :updated_at)
end

class Dummy < Rails::Application
  secrets.secret_key_base = '_'

  routes.draw do
    scope defaults: { format: :jsonapi } do
      resources :users, only: [:index]
      resources :notes, only: [:update]
    end
  end
end

class UsersController < ActionController::Base
  include JSONAPI::Fetching
  include JSONAPI::Filtering
  include JSONAPI::Pagination

  def index
    allowed_fields = [
      :first_name, :last_name, :created_at,
      :notes_created_at, :notes_quantity
    ]
    options = { sort_with_expressions: true }

    jsonapi_filter(User.all, allowed_fields, options) do |filtered|
      result = filtered.result

      if params[:sort].to_s.include?('notes_quantity')
        render jsonapi: result.group('id').to_a
        return
      end

      result = result.to_a if params[:as_list]

      jsonapi_paginate(result) do |paginated|
        render jsonapi: paginated
      end
    end
  end

  private

  def jsonapi_meta(resources)
    {
      many: true,
      pagination: jsonapi_pagination_meta(resources)
    }
  end
end

class NotesController < ActionController::Base
  include JSONAPI::Errors

  def update
    raise_error! if params[:id] == 'tada'

    note = Note.find(params[:id])

    if note.update(note_params)
      render jsonapi: note
    else
      note.errors.add(:title, message: 'has typos') if note.errors.key?(:title)

      render jsonapi_errors: note.errors, status: :unprocessable_entity
    end
  end

  private

  def render_jsonapi_internal_server_error(exception)
    Rails.logger.error(exception)
    super(exception)
  end

  def jsonapi_serializer_class(resource, is_collection)
    JSONAPI::Rails.serializer_class(resource, is_collection)
  rescue NameError
    klass = resource.class
    klass = resource.first.class if is_collection
    "Custom#{klass.name}Serializer".constantize
  end

  def note_params
    {
      title: params.require(:data).require(:attributes).require(:title),
      user_id: params.dig(:data, :relationships, :user, :id)
    }
  end

  def jsonapi_meta(resources)
    { single: true }
  end
end
