require 'jsonapi/error_serializer'
require 'jsonapi/active_model_error_serializer'

# Rails integration
module JSONAPI
  module Rails
    JSONAPI_METHODS_MAPPING = {
      meta: :jsonapi_meta,
      links: :jsonapi_pagination,
      fields: :jsonapi_fields,
      include: :jsonapi_include,
      params: :jsonapi_serializer_params
    }

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
        self.content_type = Mime[:jsonapi] if self.media_type.nil?

        many = JSONAPI::Rails.is_collection?(resource, options[:is_collection])
        resource = [resource] unless many

        return JSONAPI::Rails.serializer_to_json(
          JSONAPI::ErrorSerializer.new(resource, options)
        ) unless resource.is_a?(ActiveModel::Errors)

        model = resource.instance_variable_get(:@base)

        if respond_to?(:jsonapi_serializer_class, true)
          model_serializer = jsonapi_serializer_class(model, false)
        else
          model_serializer = JSONAPI::Rails.serializer_class(model, false)
        end

        JSONAPI::Rails.serializer_to_json(
          JSONAPI::ActiveModelErrorSerializer.new(
            resource.errors, params: {
              model: model,
              model_serializer: model_serializer
            }
          )
        )
      end
    end

    # Adds the default renderer
    #
    # @return [NilClass]
    def self.add_renderer!
      ActionController::Renderers.add(:jsonapi) do |resource, options|
        self.content_type = Mime[:jsonapi] if self.media_type.nil?

        JSONAPI_METHODS_MAPPING.to_a[0..1].each do |opt, method_name|
          next unless respond_to?(method_name, true)
          options[opt] ||= send(method_name, resource)
        end

        # If it's an empty collection, return it directly.
        many = JSONAPI::Rails.is_collection?(resource, options[:is_collection])
        if many && !resource.any?
          return options.slice(:meta, :links).compact.merge(data: []).to_json
        end

        JSONAPI_METHODS_MAPPING.to_a[2..-1].each do |opt, method_name|
          options[opt] ||= send(method_name) if respond_to?(method_name, true)
        end

        if respond_to?(:jsonapi_serializer_class, true)
          serializer_class = jsonapi_serializer_class(resource, many)
        else
          serializer_class = JSONAPI::Rails.serializer_class(resource, many)
        end

        JSONAPI::Rails.serializer_to_json(
          serializer_class.new(resource, options)
        )
      end
    end

    # Checks if an object is a collection
    #
    # Basically forwards it to a [JSONAPI::Serializer] as there's no public API
    #
    # @param resource [Object] to check
    # @param force_is_collection [NilClass] flag to overwrite
    # @return [TrueClass] upon success
    def self.is_collection?(resource, force_is_collection = nil)
      JSONAPI::ErrorSerializer.is_collection?(resource, force_is_collection)
    end

    # Resolves resource serializer class
    #
    # @return [Class]
    def self.serializer_class(resource, is_collection)
      klass = resource.class
      klass = resource.first.class if is_collection

      "#{klass.name}Serializer".constantize
    end

    # Lazily returns the serializer JSON
    #
    # @param serializer [Object] to evaluate
    # @return [String]
    def self.serializer_to_json(serializer)
      if serializer.respond_to?(:serialized_json)
        serializer.serialized_json
      else
        serializer.serializable_hash.to_json
      end
    end
  end
end
