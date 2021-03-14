require 'jsonapi/error_serializer'

module JSONAPI
  # [ActiveModel::Errors] serializer
  class ActiveModelErrorSerializer < ErrorSerializer
    class << self
      ##
      # Get the status code to render for the serializer
      #
      # This considers an optional status provided through the serializer
      # parameters, as either a symbol or a number.
      #
      # @param params [Hash]
      #     The serializer parameters
      #
      # @return [Integer]
      #     The status code to use
      def status_code(params)
        case params[:status]
        when Symbol
          Rack::Utils::SYMBOL_TO_STATUS_CODE[params[:status]]
        when Integer
          params[:status]
        else
          422
        end
      end
    end

    attribute :status do |_, params|
      status_code(params).to_s
    end

    attribute :title do |_, params|
      Rack::Utils::HTTP_STATUS_CODES[status_code(params)]
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
      elsif error_hash[:error].present? && error_hash[:error].is_a?(Symbol)
        message = errors_object.generate_message(
          error_key, error_hash[:error], error_hash
        )
      else
        message = error_hash[:message] || error_hash[:error]
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
      elsif error_key == :base
        { pointer: '/data' }
      else
        { pointer: nil }
      end
    end
  end
end
