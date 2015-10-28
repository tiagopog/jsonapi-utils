require 'jsonapi/utils/version'

module JSONAPI
  module Utils
    module Exceptions

      # 400 - Bad Request
      ################################
      class BadRequest < ::JSONAPI::Exceptions::Error

        def code
          400
        end

        def errors
          [JSONAPI::Error.new(code: 400,
                              status: :bad_request,
                              title: 'Bad Request.',
                              detail: "Sorry, but this request is not supported.")]
        end
      end

      # 500 - Internal Server Error
      ################################
      class InternalServerError < ::JSONAPI::Exceptions::Error

        def code
          500
        end

        def errors
          [JSONAPI::Error.new(code: 404,
                              status: :not_found,
                              title: 'Internal Server error.',
                              detail: "Sorry, but an error ocurred during this request.")]
        end
      end

    end
  end
end