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
        ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime[:jsonapi]] = :json
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

        many = JSONAPI::Rails.is_collection?(resource, options[:is_collection])
        resource = [resource] unless many

        return JSONAPI::ErrorSerializer.new(resource, options)
          .serialized_json unless resource.is_a?(ActiveModel::Errors)

        errors = []
        model = resource.instance_variable_get('@base')
        model_serializer = JSONAPI::Rails.serializer_class(model, false)

        details = resource.messages
        details = resource.details if resource.respond_to?(:details)

        details.each do |error_key, error_hashes|
          error_hashes.each do |error_hash|
            # Rails 4 provides just the message.
            error_hash = { message: error_hash } unless error_hash.is_a?(Hash)

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
          jsonapi_pagination(resource) if respond_to?(:jsonapi_pagination, true)
        )

        # If it's an empty collection, return it directly.
        many = JSONAPI::Rails.is_collection?(resource, options[:is_collection])
        if many && !resource.any?
          return options.slice(:meta, :links).merge(data: []).to_json
        end

        options[:fields] ||= (
          jsonapi_fields if respond_to?(:jsonapi_fields, true))
        options[:include] ||= (
          jsonapi_include if respond_to?(:jsonapi_include, true))

        serializer_class = JSONAPI::Rails.serializer_class(resource, many)
        serializer_class.new(resource, options).serialized_json
      end
    end

    # Checks if an object is a collection
    #
    # Stollen from [FastJsonapi::ObjectSerializer], instance method.
    #
    # @param resource [Object] to check
    # @param force_is_collection [NilClass] flag to overwrite
    # @return [TrueClass] upon success
    def self.is_collection?(resource, force_is_collection = nil)
      return force_is_collection unless force_is_collection.nil?

      resource.respond_to?(:size) && !resource.respond_to?(:each_pair)
    end

    # Resolves resource serializer class
    #
    # @return [Class]
    def self.serializer_class(resource, is_collection)
      klass = resource.class
      klass = resource.first.class if is_collection

      "#{klass.name}Serializer".constantize
    end
  end
end
