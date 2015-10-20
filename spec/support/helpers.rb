require 'json'

module Helpers
  module ResponseParser
    def json
      @json ||= JSON.parse(response.body)
    end
  end
end

