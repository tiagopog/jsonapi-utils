module JSONAPI
  module Utils
    module Support
      module Filter
        def apply_filter(records, options = {})
          if apply_filter?(records, options)
            records.where(filter_params)
          else
            records
          end
        end

        def apply_filter?(records, options = {})
          params[:filter].present? && records.respond_to?(:where) &&
            (options[:filter].nil? || options[:filter])
        end

        def filter_params
          @_filter_params ||=
            case params[:filter]
            when Hash, ActionController::Parameters
              default_filters.each_with_object({}) do |field, hash|
                unformatted_field = @request.unformat_key(field)
                hash[unformatted_field] = params[:filter][field]
              end
            end
        end
      end
    end
  end
end
