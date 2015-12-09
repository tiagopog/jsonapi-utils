require 'json'

module Helpers
  module ResponseParser
    def json
      @json ||= JSON.parse(response.body)
    end

    def links
      @links ||= json['links']
    end
  end
end

