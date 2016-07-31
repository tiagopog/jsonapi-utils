require 'jsonapi-resources'
require 'jsonapi/utils/version'
require 'jsonapi/utils/exceptions'
require 'jsonapi/utils/request'
require 'jsonapi/utils/response'

module JSONAPI
  module Utils
    include Request
    include Response

    def self.included(base)
      base.include ActsAsResourceController

      if base.respond_to?(:before_action)
        base.before_action :jsonapi_request_handling
      end
    end
  end
end
