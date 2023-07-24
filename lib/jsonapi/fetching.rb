module JSONAPI
  # Inclusion and sparse fields support
  module Fetching
    private
    # Extracts and formats sparse fieldsets
    #
    # Ex.: `GET /resource?fields[relationship]=id,created_at`
    #
    # @return [Hash]
    def jsonapi_fields
      return {} unless params[:fields].respond_to?(:each_pair)

      if defined?(ActiveSupport::HashWithIndifferentAccess)
        extracted = ActiveSupport::HashWithIndifferentAccess.new
      else
        extracted = Hash.new
      end

      params[:fields].each do |k, v|
        extracted[k] = v.to_s.split(',').filter_map(&:strip)
      end

      extracted
    end

    # Extracts and whitelists allowed includes
    #
    # Ex.: `GET /resource?include=relationship,relationship.subrelationship`
    #
    # @return [Array]
    def jsonapi_include
      params['include'].to_s.split(',').filter_map(&:strip)
    end
  end
end
