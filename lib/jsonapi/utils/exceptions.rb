require 'jsonapi/utils/version'

module JSONAPI
  module Utils
    module Exceptions
      class ActiveRecord < ::JSONAPI::Exceptions::Error
        attr_accessor :object

        def initialize(object)
          @object = object
        end

        def errors
          object.errors.keys.map do |key|
            JSONAPI::Error.new(
              code: JSONAPI::VALIDATION_ERROR,
              status: :unprocessable_entity,
              id: key,
              title: object.errors.full_messages_for(key).first
            )
          end
        end
      end

      class BadRequest < ::JSONAPI::Exceptions::Error
        def code; '400' end

        def errors
          [JSONAPI::Error.new(
              code: code,
              status: :bad_request,
              title: 'Bad Request',
              detail: 'This request is not supported.'
            )]
        end
      end

      class InternalServerError < ::JSONAPI::Exceptions::Error
        def code; '500' end

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
