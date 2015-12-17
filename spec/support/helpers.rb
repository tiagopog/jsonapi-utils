require 'json'

module Helpers
  module ResponseParser
    def data
      json['data'].is_a?(Array) ? json['data'] : [json['data']]
    end

    def json
      @json ||= JSON.parse(response.body)
    end

    def links
      @links ||= json['links']
    end
  end
end
