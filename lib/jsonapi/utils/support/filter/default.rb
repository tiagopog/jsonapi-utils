module JSONAPI::Utils::Support::Filter
  module Default
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
          default_filters.each_with_object({}) do |resource, hash|
            hash[resource] = params[:filter][resource]
          end
        end
    end

    private

    def default_filters
      params[:filter].keys.map(&:to_sym) - @request.resource_klass._custom_filters
    end
  end
end
