require 'rack/utils'

module JSONAPI
  # Helpers to handle some error responses
  #
  # Most of the exceptions are handled in Rails by [ActionDispatch] middleware
  # See: https://api.rubyonrails.org/classes/ActionDispatch/ExceptionWrapper.html
  module Errors
    # Callback will register the error handlers
    #
    # @return [Module]
    def self.included(base)
      base.class_eval do
        rescue_from(
          StandardError,
          with: :render_jsonapi_internal_server_error
        ) unless defined?(::Rails) && ::Rails.env.test?

        rescue_from(
          ActiveRecord::RecordNotFound,
          with: :render_jsonapi_not_found
        ) if defined?(ActiveRecord::RecordNotFound)

        rescue_from(
          ActionController::ParameterMissing,
          with: :render_jsonapi_unprocessable_entity
        ) if defined?(ActionController::ParameterMissing)
      end
    end

    private
    # Generic error handler callback
    #
    # @param exception [Exception] instance to handle
    # @return [String] JSONAPI error response
    def render_jsonapi_internal_server_error(exception)
      error = { status: '500', title: Rack::Utils::HTTP_STATUS_CODES[500] }
      render jsonapi_errors: [error], status: :internal_server_error
    end

    # Not found (404) error handler callback
    #
    # @param exception [Exception] instance to handle
    # @return [String] JSONAPI error response
    def render_jsonapi_not_found(exception)
      error = { status: '404', title: Rack::Utils::HTTP_STATUS_CODES[404] }
      render jsonapi_errors: [error], status: :not_found
    end

    # Unprocessable entity (422) error handler callback
    #
    # @param exception [Exception] instance to handle
    # @return [String] JSONAPI error response
    def render_jsonapi_unprocessable_entity(exception)
      source = { pointer: '' }

      if !%w{data attributes relationships}.include?(exception.param.to_s)
        source[:pointer] = "/data/attributes/#{exception.param}"
      end

      error = {
        status: '422',
        title: Rack::Utils::HTTP_STATUS_CODES[422],
        source: source
      }

      render jsonapi_errors: [error], status: :unprocessable_entity
    end
  end
end
