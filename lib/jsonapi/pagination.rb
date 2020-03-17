module JSONAPI
  # Pagination support
  module Pagination
    private
    # Default number of items per page.
    JSONAPI_PAGE_SIZE = 30

    # Applies pagination to a set of resources
    #
    # Ex.: `GET /resource?page[number]=2&page[size]=10`
    #
    # @return [ActiveRecord::Base] a collection of resources
    def jsonapi_paginate(resources)
      offset, limit, _ = jsonapi_pagination_params

      if resources.respond_to?(:offset)
        resources = resources.offset(offset).limit(limit)
      else
        original_size = resources.size
        resources = resources[(offset)..(offset + limit - 1)] || []

        # Cache the original resources size to be used for pagination meta
        resources.instance_variable_set(:@original_size, original_size)
      end

      block_given? ? yield(resources) : resources
    end

    # Generates the pagination links
    #
    # @return [Array]
    def jsonapi_pagination(resources)
      links = { self: request.base_url + request.fullpath }
      pagination = jsonapi_pagination_meta(resources)

      return links if pagination.blank?

      original_params = params.except(
        *jsonapi_path_parameters.keys.map(&:to_s)
      ).as_json.with_indifferent_access

      original_params[:page] = original_params[:page].dup || {}
      original_url = request.base_url + request.path + '?'

      pagination.each do |page_name, number|
        original_params[:page][:number] = number
        links[page_name] = original_url + CGI.unescape(
          original_params.to_query
        )
      end

      links
    end

    # Generates pagination numbers
    #
    # @return [Hash] with the first, previous, next, current, last page numbers
    def jsonapi_pagination_meta(resources)
      return {} unless JSONAPI::Rails.is_collection?(resources)

      _, limit, page = jsonapi_pagination_params

      numbers = { current: page }

      if resources.respond_to?(:unscope)
        total = resources.unscope(:limit, :offset, :order).count()
      else
        # Try to fetch the cached size first
        total = resources.instance_variable_get(:@original_size)
        total ||= resources.size
      end

      last_page = [1, (total.to_f / limit).ceil].max

      if page > 1
        numbers[:first] = 1
        numbers[:prev] = page - 1
      end

      if page < last_page
        numbers[:next] = page + 1
        numbers[:last] = last_page
      end

      numbers
    end

    # Extracts the pagination params
    #
    # @return [Array] with the offset, limit and the current page number
    def jsonapi_pagination_params
      def_per_page = self.class.const_get(:JSONAPI_PAGE_SIZE).to_i

      pagination = params[:page].try(:slice, :number, :size) || {}
      per_page = pagination[:size].to_f.to_i
      per_page = def_per_page if per_page > def_per_page || per_page < 1
      num = [1, pagination[:number].to_f.to_i].max

      [(num - 1) * per_page, per_page, num]
    end

    # Fallback to Rack's parsed query string when Rails is not available
    #
    # @return [Hash]
    def jsonapi_path_parameters
      return request.path_parameters if request.respond_to?(:path_parameters)

      request.send(:parse_query, request.query_string, '&;')
    end
  end
end
