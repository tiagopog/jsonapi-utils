require 'jsonapi-resources'
require 'jsonapi/utils/version'
require 'jsonapi/utils/exceptions'
require 'jsonapi/utils/request'
require 'jsonapi/utils/response'
require 'jsonapi/utils/support/filter/custom'

JSONAPI::Resource.extend JSONAPI::Utils::Support::Filter::Custom

module JSONAPI
  module Utils
    def self.included(base)
      base.include ActsAsResourceController
      base.include Request
      base.include Response

      if base.respond_to?(:before_action)
        base.before_action :jsonapi_request_handling
      end
    end
  end
end
