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
      @_allowed_custom_filters ||= []
      @_allowed_custom_filters |= [attr]
    end
  end
end
