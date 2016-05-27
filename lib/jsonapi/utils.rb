require 'jsonapi-resources'
require 'jsonapi/utils/version'
require 'jsonapi/utils/exceptions'
require 'jsonapi/utils/request'
require 'jsonapi/utils/response'

module JSONAPI
  module Utils
    include JSONAPI::Utils::Request
    include JSONAPI::Utils::Response

    def self.included(base)
      if base.respond_to?(:before_action)
        base.before_action :setup_request, :check_request
      end
    end
  end
end
