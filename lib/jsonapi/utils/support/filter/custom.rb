module JSONAPI::Utils::Support::Filter
  module Custom
    attr_reader :_custom_filters

    def custom_filters(*attrs)
      attrs.each { |attr| custom_filter(attr) }
    end

    def custom_filter(attr)
      attr = attr.to_sym
      @_allowed_filters[attr] = {}

      if !@_custom_filters.is_a?(Array)
        @_custom_filters = Array(attr)
      elsif @_custom_filters.include?(attr)
        @_custom_filters.push(attr)
      end
    end
  end
end
