require 'jsonapi/serializer'

module JSONAPI
  # A simple error serializer
  class ErrorSerializer
    include JSONAPI::Serializer

    set_type :error

    # Object/Hash attribute helpers.
    [:status, :source, :title, :detail, :code, :links].each do |attr_name|
      attribute attr_name do |object|
        object.try(attr_name) || object.try(:fetch, attr_name, nil)
      end
    end

    # Overwrite the ID extraction method, to skip validations
    #
    # @return [NilClass]
    def self.id_from_record(_record, _params)
    end

    # Remap the root key to `errors`
    #
    # @return [Hash]
    def serializable_hash
      { errors: (super[:data] || []).map { |error| error[:attributes] } }
    end
  end
end
