require 'jsonapi/error_serializer'
require 'jsonapi/deserialization'

module JSONAPI
  # [ActiveModel::Errors] serializer
  class ActiveModelErrorSerializer < ErrorSerializer
    extend ::JSONAPI::Deserialization

    # Cleanups to DRY things...
    singleton_class.undef_method :jsonapi_deserialize

    attribute :status do
      '422'
    end

    attribute :title do
      Rack::Utils::HTTP_STATUS_CODES[422]
    end

    attribute :code do |object|
      object.type.to_s.delete("''").parameterize.tr('-', '_')
    end

    attribute :detail do |object, _params|
      object.full_message
    end

    attribute :source do |object, params|
      error_key = object.attribute
      model_serializer = params[:model_serializer]
      attrs = (model_serializer.attributes_to_serialize || {}).keys
      rels = (model_serializer.relationships_to_serialize || {}).keys

      # Revert back to underscore any serializer transformation...
      [attrs, rels].each do |skeys|
        skeys.map! { |skey| jsonapi_inflector.underscore(skey) }
      end

      if attrs.include?(error_key)
        { pointer: "/data/attributes/#{error_key}" }
      elsif rels.include?(error_key)
        { pointer: "/data/relationships/#{error_key}" }
      else
        { pointer: '' }
      end
    end
  end
end
