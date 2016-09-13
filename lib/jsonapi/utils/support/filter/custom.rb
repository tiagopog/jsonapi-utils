module JSONAPI::Utils::Support::Filter
  module Custom
    def _custom_filters
      @_allowed_custom_filters || []
    end

    def custom_filters(*attrs)
      attrs.each { |attr| custom_filter(attr) }
    end

    def custom_filter(attr)
      attr = attr.to_sym
      @_allowed_filters[attr] = {}

      if !@_allowed_custom_filters.is_a?(Array)
        @_allowed_custom_filters = Array(attr)
      elsif @_allowed_custom_filters.include?(attr)
        @_allowed_custom_filters.push(attr)
      end
    end
  end
end
