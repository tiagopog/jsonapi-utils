module JSONAPI
  module Utils
    module Exceptions
      class InternalServerError < ::JSONAPI::Exceptions::Error
        # HTTP status code
        #
        # @return [String]
        #
        # @api public
        def code
          '500'
        end

        # Decorate errors for 500 responses.
        #
        # @return [Array]
        #
        # @api public
        def errors
          [JSONAPI::Error.new(
            code: code,
            status: :internal_server_error,
            title: 'Internal Server Error',
            detail: 'An internal error ocurred while processing the request.'
          )]
        end
      end
    end
  end
end
