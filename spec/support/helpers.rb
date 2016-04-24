require 'json'

module Helpers
  module ResponseParser
    def data
      @data ||= json['data']
    end

    def error
      @error ||= json['errors'].first
    end

    def json
      @json ||= JSON.parse(response.body)
    end

    def links
      @links ||= json['links']
    end
  end
end
