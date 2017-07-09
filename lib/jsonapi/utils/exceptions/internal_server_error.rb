module JSONAPI
  module Utils
    module Exceptions
      class InternalServerError < ::JSONAPI::Exceptions::Error
        def code
          '500'
        end

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
