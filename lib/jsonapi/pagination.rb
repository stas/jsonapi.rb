# Pagination support
module JSONAPI::Pagination
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
      resources = resources[(offset)..(offset + limit)]
    end

    block_given? ? yield(resources) : resources
  end

  # Generates the pagination links
  #
  # @return [Array]
  def jsonapi_pagination(resources)
    links = {
      self: request.base_url + request.original_fullpath
    }

    return links unless resources.respond_to?(:many?)

    _, limit, page = jsonapi_pagination_params

    original_params = params.except(
      *request.path_parameters.keys.map(&:to_s)).to_unsafe_h
    original_params[:page] ||= {}
    original_url = request.base_url + request.path + '?'

    if resources.respond_to?(:unscope)
      total = resources.unscope(:limit, :offset).count()
    else
      total = resources.size
    end

    last_page = [1, (total.to_f / limit).ceil].max

    if page > 1
      original_params[:page][:number] = 1
      links[:first] = original_url + CGI.unescape(original_params.to_query)
      original_params[:page][:number] = page - 1
      links[:prev] = original_url + CGI.unescape(original_params.to_query)
    end

    if page < last_page
      original_params[:page][:number] = page + 1
      links[:next] = original_url + CGI.unescape(original_params.to_query)
      original_params[:page][:number] = last_page
      links[:last] = original_url + CGI.unescape(original_params.to_query)
    end

    links
  end

  # Extracts the pagination params
  #
  # @return [Array] with the offset, limit and the current page number
  def jsonapi_pagination_params
    def_per_page = self.class.const_get(:JSONAPI_PAGE_SIZE).to_i

    pagination = params[:page].try(:slice, :number, :size) || {}
    per_page = (pagination[:size] || def_per_page).to_f.to_i
    per_page = def_per_page if per_page > def_per_page
    num = [1, pagination[:number].to_f.to_i].max

    [(num - 1) * per_page, per_page, num]
  end
end
