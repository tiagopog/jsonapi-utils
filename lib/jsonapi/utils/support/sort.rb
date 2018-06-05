module JSONAPI::Utils::Support
  module Sort
    # Apply sort on result set (ascending by default).
    #   e.g.: User.order(:first_name)
    #
    # @param records [ActiveRecord::Relation, Array] collection of records
    #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
    #
    # @return [ActiveRecord::Relation, Array]
    #
    # @api public
    def apply_sort(records)
      return records unless params[:sort].present?

      if records.is_a?(Array)
        records.sort { |a, b| comp = 0; eval(sort_criteria) }
      elsif records.respond_to?(:order)
        records.order(sort_params)
      else
        records
      end
    end

    # Build the criteria to be evaluated wthen applying sort
    # on Array of Hashes (ascending by default).
    #
    # @return [String]
    #
    # @api public
    def sort_criteria
      @sort_criteria ||=
        sort_params.reduce('') do |sum, (key, value)|
          comparables = ["a[:#{key}]", "b[:#{key}]"]
          comparables.reverse! if value == :desc
          sum + "comp = comp == 0 ? #{comparables.join(' <=> ')} : comp; "
        end
    end

    # Build a Hash with the sort criteria.
    #
    # @return [Hash, NilClass]
    #
    # @api public
    def sort_params
      @_sort_params ||=
        if params[:sort].present?
          params[:sort].split(',').each_with_object({}) do |field, hash|
            unformatted_field  = @request.unformat_key(field)
            desc, field        = unformatted_field.to_s.match(/^([-_])?(\w+)$/i)[1..2]
            hash[field.to_sym] = desc.present? ? :desc : :asc
          end
        end
    end
  end
end
