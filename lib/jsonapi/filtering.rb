require 'ransack/predicate'

# Filtering and sorting support
module JSONAPI::Filtering
  private

  # Applies filtering and sorting to a set of resources if requested
  #
  # The fields follow [Ransack] specifications.
  # See: https://github.com/activerecord-hackery/ransack#search-matchers
  #
  # Ex.: `GET /resource?filter[region_matches_any]=Lisb%&sort=-created_at,id`
  #
  # @param allowed_fields [Array] a list of allowed fields to be filtered
  # @return [ActiveRecord::Base] a collection of resources
  def jsonapi_filter(resources, allowed_fields)
    extracted_params = jsonapi_filter_params(allowed_fields)
    extracted_params[:sorts] = jsonapi_sort_params(allowed_fields)
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
      field_name = requested_field.dup
      predicate = Ransack::Predicate.detect_and_strip_from_string!(field_name)
      predicate = Ransack::Predicate.named(predicate)

      field_names = field_name.split(/_and_|_or_/)

      if to_filter.is_a?(String) && to_filter.include?(',')
        to_filter = to_filter.split(',')
      end

      if predicate && (field_names - allowed_fields).empty?
        filtered[requested_field] = to_filter
      end
    end

    filtered
  end

  # Extracts and whitelists allowed fields to be sorted
  #
  # @param allowed_fields [Array] a list of allowed fields to be sorted
  # @return [Hash] to be passed to [ActiveRecord::Base#order]
  def jsonapi_sort_params(allowed_fields)
    requested = params[:sort].to_s.split(',')
    requested.map! do |requested_field|
      desc = requested_field.to_s.start_with?('-')
      [
        desc ? requested_field[1..-1] : requested_field,
        desc ? 'desc' : 'asc'
      ]
    end

    # Convert to strings instead of hashes to allow joined table columns.
    requested.to_h.slice(*allowed_fields.map(&:to_s)).map do |field, dir|
      [field, dir].join(' ')
    end
  end
end
