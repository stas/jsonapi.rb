require 'securerandom'
require 'rails/all'
require 'ransack'
require 'jsonapi'

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

  def self.ransackable_attributes(auth_object = nil)
    %w(created_at first_name id last_name updated_at)
  end

  def self.ransackable_associations(auth_object = nil)
    %w(notes)
  end
end

class Note < ActiveRecord::Base
  validate :title_cannot_contain_slurs
  validates_format_of :title, without: /BAD_TITLE/
  validates_numericality_of :quantity, less_than: 100, if: :quantity?
  belongs_to :user, required: true

  def self.ransackable_associations(auth_object = nil)
    %w(user)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(created_at id quantity title updated_at user_id)
  end

  private
  def title_cannot_contain_slurs
    errors.add(:base, 'Title has slurs') if title.to_s.include?('SLURS')
  end
end

class CustomNoteSerializer
  include JSONAPI::Serializer

  set_type :note
  belongs_to :user
  attributes(:title, :quantity, :created_at, :updated_at)
end

class UserSerializer
  include JSONAPI::Serializer

  has_many :notes, serializer: CustomNoteSerializer
  attributes(:last_name, :created_at, :updated_at)

  attribute :first_name do |object, params|
    if params[:first_name_upcase]
      object.first_name.upcase
    else
      object.first_name
    end
  end
end

class Dummy < Rails::Application
  config.secret_key_base = '_'
  config.hosts << 'www.example.com' if config.respond_to?(:hosts)

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
  include JSONAPI::Deserialization

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
        paginated = paginated.to_a if params[:decorate_after_pagination]
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

  def jsonapi_serializer_params
    {
      first_name_upcase: params[:upcase]
    }
  end
end

class NotesController < ActionController::Base
  include JSONAPI::Errors
  include JSONAPI::Deserialization

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
    # Will trigger required attribute error handling
    params.require(:data).require(:attributes).require(:title)

    jsonapi_deserialize(params)
  end

  def jsonapi_meta(resources)
    { single: true }
  end
end
