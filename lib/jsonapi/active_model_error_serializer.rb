require 'jsonapi/error_serializer'

module JSONAPI
  # [ActiveModel::Errors] serializer
  class ActiveModelErrorSerializer < ErrorSerializer
    attribute :status do
      '422'
    end

    attribute :title do
      Rack::Utils::HTTP_STATUS_CODES[422]
    end

    attribute :code do |object|
      _, error_hash = object
      code = error_hash[:error] unless error_hash[:error].is_a?(Hash)
      code ||= error_hash[:message] || :invalid
      # `parameterize` separator arguments are different on Rails 4 vs 5...
      code.to_s.delete("''").parameterize.tr('-', '_')
    end

    attribute :detail do |object, params|
      error_key, error_hash = object
      errors_object = params[:model].errors

      # Rails 4 provides just the message.
      if error_hash[:error].present? && error_hash[:error].is_a?(Hash)
        message = errors_object.generate_message(
          error_key, nil, error_hash[:error]
        )
      elsif error_hash[:error].present?
        message = errors_object.generate_message(
          error_key, error_hash[:error], error_hash
        )
      else
        message = error_hash[:message]
      end

      errors_object.full_message(error_key, message)
    end

    attribute :source do |object, params|
      error_key, _ = object
      model_serializer = params[:model_serializer]
      attrs = (model_serializer.attributes_to_serialize || {}).keys
      rels = (model_serializer.relationships_to_serialize || {}).keys

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
