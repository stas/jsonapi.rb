require 'net/http/status'
require 'active_support/concern'

# Helpers to handle some error responses
#
# Most of the exceptions are handled in Rails by [ActionDispatch] middleware
# See: https://api.rubyonrails.org/classes/ActionDispatch/ExceptionWrapper.html
module JSONAPI::Errors
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      error = { status: '500', title: Net::HTTP::STATUS_CODES[500] }
      render jsonapi_errors: [error], status: :internal_server_error
    end

    [
      ActiveRecord::RecordNotFound
    ].each do |exception_class|
      rescue_from exception_class do |exception|
        error = { status: '404', title: Net::HTTP::STATUS_CODES[404] }
        render jsonapi_errors: [error], status: :not_found
      end
    end

    [
      ActionController::ParameterMissing
    ].each do |exception_class|
      rescue_from exception_class do |exception|
        source = { pointer: '' }

        if !%w{data attributes relationships}.include?(exception.param.to_s)
          source[:pointer] = "/data/attributes/#{exception.param}"
        end

        error = {
          status: '422',
          title: Net::HTTP::STATUS_CODES[422],
          source: source
        }

        render jsonapi_errors: [error], status: :unprocessable_entity
      end
    end
  end
end
