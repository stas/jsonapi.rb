begin
  require 'ransack/predicate'
  require_relative 'patches'
rescue LoadError
end

# Filtering and sorting support
module JSONAPI
  module Filtering
    # Parses and returns the attribute and the predicate of a ransack field
    #
    # @param requested_field [String] the field to parse
    # @return [Array] with the fields and the predicate
    def self.extract_attributes_and_predicates(requested_field)
      predicates = []
      field_name = requested_field.to_s.dup

      while Ransack::Predicate.detect_from_string(field_name).present? do
        predicate = Ransack::Predicate
          .detect_and_strip_from_string!(field_name)
        predicates << Ransack::Predicate.named(predicate)
      end

      [field_name.split(/_and_|_or_/), predicates.reverse]
    end

    private
    # Applies filtering and sorting to a set of resources if requested
    #
    # The fields follow [Ransack] specifications.
    # See: https://github.com/activerecord-hackery/ransack#search-matchers
    #
    # Ex.: `GET /resource?filter[region_matches_any]=Lisb%&sort=-created_at,id`
    #
    # @param allowed_fields [Array] a list of allowed fields to be filtered
    # @param options [Hash] extra flags to enable/disable features
    # @return [ActiveRecord::Base] a collection of resources
    def jsonapi_filter(resources, allowed_fields, options = {})
      allowed_fields = allowed_fields.map(&:to_s)
      extracted_params = jsonapi_filter_params(allowed_fields)
      extracted_params[:sorts] = jsonapi_sort_params(allowed_fields, options)
      resources = resources.ransack(extracted_params)
      block_given? ? yield(resources) : resources
    end

    # Extracts and whitelists allowed fields to be filtered
    #
    # The fields follow [Ransack] specifications.
    # See: https://github.com/activerecord-hackery/ransack#search-matchers
    #
    # @param allowed_fields [Array] a list of allowed fields to be filtered
    # @return [Hash] to be passed to [ActiveRecord::Base#order]
    def jsonapi_filter_params(allowed_fields)
      filtered = {}
      requested = params[:filter] || {}
      allowed_fields = allowed_fields.map(&:to_s)

      requested.each_pair do |requested_field, to_filter|
        field_names, predicates = JSONAPI::Filtering
          .extract_attributes_and_predicates(requested_field)

        wants_array = predicates.any? && predicates.map(&:wants_array).any?

        if to_filter.is_a?(String) && wants_array
          to_filter = to_filter.split(',')
        end

        if predicates.any? && (field_names - allowed_fields).empty?
          filtered[requested_field] = to_filter
        end
      end

      filtered
    end

    # Extracts and whitelists allowed fields (or expressions) to be sorted
    #
    # @param allowed_fields [Array] a list of allowed fields to be sorted
    # @param options [Hash] extra options to enable/disable features
    # @return [Hash] to be passed to [ActiveRecord::Base#order]
    def jsonapi_sort_params(allowed_fields, options = {})
      filtered = []
      requested = params[:sort].to_s.split(',')

      requested.each do |requested_field|
        if requested_field.to_s.start_with?('-')
          dir = 'desc'
          requested_field = requested_field[1..-1]
        else
          dir = 'asc'
        end

        field_names, predicates = JSONAPI::Filtering
          .extract_attributes_and_predicates(requested_field)

        next unless (field_names - allowed_fields).empty?
        next if !options[:sort_with_expressions] && predicates.any?

        # Convert to strings instead of hashes to allow joined table columns.
        filtered << [requested_field, dir].join(' ')
      end

      filtered
    end
  end
end
