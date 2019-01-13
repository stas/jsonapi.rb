require 'jsonapi/error_serializer'
require 'jsonapi/active_model_error_serializer'

# Rails integration
module JSONAPI
  module Rails
    # Updates the mime types and registers the renderers
    #
    # @return [NilClass]
    def self.install!
      return unless defined?(::Rails)

      Mime::Type.register JSONAPI::MEDIA_TYPE, :jsonapi

      # Map the JSON parser to the JSONAPI mime type requests.
      if ::Rails::VERSION::MAJOR >= 5
        parser = ActionDispatch::Request.parameter_parsers[:json]
        ActionDispatch::Request.parameter_parsers[:jsonapi] = parser
      else
        parser = ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime[:json]]
        ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime[:jsonapi]] = parser
      end

      self.add_renderer!
      self.add_errors_renderer!
    end

    # Adds the error renderer
    #
    # @return [NilClass]
    def self.add_errors_renderer!
      ActionController::Renderers.add(:jsonapi_errors) do |resource, options|
        self.content_type ||= Mime[:jsonapi]

        resource = [resource] unless JSONAPI::Rails.is_collection?(resource)

        return JSONAPI::ErrorSerializer.new(resource, options)
          .serialized_json unless resource.is_a?(ActiveModel::Errors)

        errors = []
        model = resource.marshal_dump.first
        model_serializer = JSONAPI::Rails.serializer_class(model)

        resource.details.each do |error_key, error_hashes|
          error_hashes.each do |error_hash|
            errors << [ error_key, error_hash ]
          end
        end

        JSONAPI::ActiveModelErrorSerializer.new(
          errors, params: { model: model, model_serializer: model_serializer }
        ).serialized_json
      end
    end

    # Adds the default renderer
    #
    # @return [NilClass]
    def self.add_renderer!
      ActionController::Renderers.add(:jsonapi) do |resource, options|
        self.content_type ||= Mime[:jsonapi]

        options[:meta] ||= (
          jsonapi_meta(resource) if respond_to?(:jsonapi_meta, true))
        options[:links] ||= (
          jsonapi_pagination(resource) if respond_to?(:jsonapi_pagination, true))

        # If it's an empty collection, return it directly.
        if JSONAPI::Rails.is_collection?(resource) && !resource.any?
          return options.slice(:meta, :links).merge(data: []).to_json
        end

        options[:fields] ||= jsonapi_fields if respond_to?(:jsonapi_fields, true)
        options[:include] ||= (
          jsonapi_include if respond_to?(:jsonapi_include, true))

        serializer_class = JSONAPI::Rails.serializer_class(resource)
        serializer_class.new(resource, options).serialized_json
      end
    end

    # Checks if an object is a collection
    #
    # @param object [Object] to check
    # @return [TrueClass] upon success
    def self.is_collection?(object)
      object.is_a?(Enumerable) && !object.respond_to?(:each_pair)
    end

    # Resolves resource serializer class
    #
    # @return [Class]
    def self.serializer_class(resource)
      klass = resource.class
      klass = resource.first.class if self.is_collection?(resource)

      "#{klass.name}Serializer".constantize
    end
  end
end
