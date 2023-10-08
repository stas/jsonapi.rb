begin
  require 'active_support/inflector'
rescue LoadError
  warn(
    'Trying to load `dry-inflector` as an ' \
    'alternative to `active_support/inflector`...'
  )
  require 'dry/inflector'
end

module JSONAPI
  # Helpers to transform a JSON API document, containing a single data object,
  # into a hash that can be used to create an [ActiveRecord::Base] instance.
  #
  # Initial version from the `active_model_serializers` support for JSONAPI.
  module Deserialization
    private
    # Helper method to pick an available inflector implementation
    #
    # @return [Object]
    def jsonapi_inflector
      ActiveSupport::Inflector
    rescue
      Dry::Inflector.new
    end

    # Returns a transformed dictionary following [ActiveRecord::Base] specs
    #
    # @param [Hash|ActionController::Parameters] document
    # @param [Hash] options
    #   only: Array of symbols of whitelisted fields.
    #   except: Array of symbols of blacklisted fields.
    #   polymorphic: Array of symbols of polymorphic fields.
    # @return [Hash]
    def jsonapi_deserialize(document, options = {})
      if document.respond_to?(:permit!)
        # Handle Rails params...
        primary_data = document.dup.require(:data).permit!.as_json
      elsif document.is_a?(Hash)
        primary_data = (document.as_json['data'] || {}).deep_dup
      else
        return {}
      end

      # Transform keys and any option values.
      options = options.as_json
      ['only', 'except', 'polymorphic'].each do |opt_name|
        opt_value = options[opt_name]
        options[opt_name] = Array(opt_value).map(&:to_s) if opt_value
      end

      relationships = primary_data['relationships'] || {}
      parsed = primary_data['attributes'] || {}
      parsed['id'] = primary_data['id'] if primary_data['id']

      # Remove unwanted items from a dictionary.
      if options['only']
        [parsed, relationships].map { |hsh| hsh.slice!(*options['only']) }
      elsif options['except']
        [parsed, relationships].map { |hsh| hsh.except!(*options['except']) }
      end

      relationships.map do |assoc_name, assoc_data|
        assoc_data = (assoc_data || {})['data'] || {}
        rel_name = jsonapi_inflector.singularize(assoc_name)

        if assoc_data.is_a?(Array)
          parsed["#{rel_name}_ids"] = assoc_data.filter_map { |ri| ri['id'] }
          next
        end

        parsed["#{rel_name}_id"] = assoc_data['id']

        if (options['polymorphic'] || []).include?(assoc_name)
          rel_type = jsonapi_inflector.classify(assoc_data['type'].to_s)
          parsed["#{rel_name}_type"] = rel_type
        end
      end

      parsed
    end
  end
end
