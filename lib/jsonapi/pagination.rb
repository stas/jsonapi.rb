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

      # Cache the original resources size to be used for pagination meta
      @_jsonapi_original_size = resources.size

      if resources.respond_to?(:offset)
        resources = resources.offset(offset).limit(limit)
      else
        resources = resources[(offset)..(offset + limit - 1)] || []
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
        next if page_name == :records

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

      total = @_jsonapi_original_size

      last_page = [1, (total.to_f / limit).ceil].max

      if page > 1
        numbers[:first] = 1
        numbers[:prev] = page - 1
      end

      if page < last_page
        numbers[:next] = page + 1
        numbers[:last] = last_page
      end

      if total.present?
        numbers[:records] = total
      end

      numbers
    end

    # Extracts the pagination params
    #
    # @return [Array] with the offset, limit and the current page number
    def jsonapi_pagination_params
      pagination = params[:page].try(:slice, :number, :size) || {}
      per_page = jsonapi_page_size(pagination)
      num = [1, pagination[:number].to_f.to_i].max

      [(num - 1) * per_page, per_page, num]
    end

    # Retrieves the default page size
    #
    # @param per_page_param [Hash] opts the paginations params
    # @option opts [String] :number the page number requested
    # @option opts [String] :size the page size requested
    #
    # @return [Integer]
    def jsonapi_page_size(pagination_params)
      per_page = pagination_params[:size].to_f.to_i

      return self.class
              .const_get(:JSONAPI_PAGE_SIZE)
              .to_i if per_page < 1

      per_page
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
