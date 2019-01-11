require 'fast_jsonapi'

module JSONAPI
  # A simple error serializer
  class ErrorSerializer
    include FastJsonapi::ObjectSerializer

    set_id :object_id
    set_type :error

    # Object/Hash attribute helpers.
    [:status, :source, :title, :detail].each do |attr_name|
      attribute attr_name do |object|
        object.try(attr_name) || object.try(:fetch, attr_name, nil)
      end
    end

    # Remap the root key to `errors`
    #
    # @return [Hash]
    def serializable_hash
      { errors: (super[:data] || []).map { |error| error[:attributes] } }
    end
  end
end
