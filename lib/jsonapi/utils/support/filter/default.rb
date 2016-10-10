module JSONAPI::Utils::Support::Filter
  module Default
    # Apply default equality filters.
    #   e.g.: User.where(name: 'Foobar')
    #
    # @param records [ActiveRecord::Relation, Array] collection of records
    #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
    #
    # @param options [Hash] JU's options
    #   e.g.: { filter: false, paginate: false }
    #
    # @return [ActiveRecord::Relation, Array]
    #
    # @api public
    def apply_filter(records, options = {})
      if apply_filter?(records, options)
        records.where(filter_params)
      else
        records
      end
    end

    # Check whether default filters should be applied.
    #
    # @param records [ActiveRecord::Relation, Array] collection of records
    #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
    #
    # @param options [Hash] JU's options
    #   e.g.: { filter: false, paginate: false }
    #
    # @return [Boolean]
    #
    # @api public
    def apply_filter?(records, options = {})
      params[:filter].present? && records.respond_to?(:where) &&
        (options[:filter].nil? || options[:filter])
    end

    # Build a Hash with the default filters.
    #
    # @return [Hash, NilClass]
    #
    # @api public
    def filter_params
      @_filter_params ||=
        case params[:filter]
        when Hash, ActionController::Parameters
          default_filters.each_with_object({}) do |field, hash|
            unformatted_key = @request.unformat_key(field)
            hash[unformatted_key] = params[:filter][field]
          end
        end
    end

    private

    # Take all allowed filters and remove the custom ones.
    #
    # @return [Array]
    #
    # @api private
    def default_filters
      params[:filter].keys.map(&:to_sym) - @request.resource_klass._custom_filters
    end
  end
end
