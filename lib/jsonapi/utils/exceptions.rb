require 'jsonapi/utils/version'

module JSONAPI
  module Utils
    module Exceptions
      class ActiveRecord < ::JSONAPI::Exceptions::Error
        attr_accessor :object, :associations, :association_keys, :foreign_keys

        def initialize(object)
          @object = object

          # Need to reflect on object's associations for error reporting.
          @associations     = @object.class.reflect_on_all_associations(:belongs_to)
          @association_keys = @associations.map(&:name)
          @foreign_keys     = @associations.map(&:foreign_key).map(&:to_sym)
        end

        def errors
          object.errors.keys.map do |key|
            error_meta = error_meta_for(key)

            JSONAPI::Error.new(
              code: JSONAPI::VALIDATION_ERROR,
              status: :unprocessable_entity,
              id: error_meta[:id],
              title: object.errors.full_messages_for(key).first,
              source: { pointer: error_meta[:pointer] }
            )
          end
        end

        private

        # Returns JSON pointer for a given error key.
        # See https://tools.ietf.org/html/rfc6901 for more information about
        # JSON pointers.
        def error_meta_for(key)
          # Pointer depends on whether we're using an association, foreign
          # key, base, or attribute.
          if association_keys.include?(key)
            { id: key, pointer: "/data/relationships/#{key}" }
          elsif foreign_keys.include?(key)
            error_key = associations.select { |a| a.foreign_key.to_sym == key }.first.name
            { id: error_key, pointer: "/data/relationships/#{error_key}" }
          elsif key == :base
            { id: key, pointer: '/data' }
          else
            { id: key, pointer: "/data/attributes/#{key}" }
          end
        end
      end

      class BadRequest < ::JSONAPI::Exceptions::Error
        def code
          '400'
        end

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
