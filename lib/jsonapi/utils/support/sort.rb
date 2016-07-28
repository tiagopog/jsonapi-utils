module JSONAPI
  module Utils
    module Support
      module Sort
        def apply_sort(records)
          return records unless params[:sort].present?

          if records.is_a?(Array)
            records.sort { |a, b| comp = 0; eval(sort_criteria) }
          elsif records.respond_to?(:order)
            records.order(sort_params)
          end
        end

        def sort_criteria
          sort_params.reduce('') do |sum, (key, value)|
            comparables = ["a[:#{key}]", "b[:#{key}]"]
            comparables.reverse! if value == :desc
            sum + "comp = comp == 0 ? #{comparables.join(' <=> ')} : comp; "
          end
        end

        def sort_params
          @_sort_params ||=
            if params[:sort].present?
              params[:sort].split(',').each_with_object({}) do |criteria, hash|
                order, field = criteria.match(/(\-?)(\w+)/i)[1..2]
                hash[field]  = order == '-' ? :desc : :asc
              end
            end
        end
      end
    end
  end
end
