require 'jsonapi/utils/version'

module JSONAPI
  module Utils
    module Exceptions
      class ActiveRecord < ::JSONAPI::Exceptions::Error
        attr_accessor :object, :resource, :relationships, :relationship_keys, :foreign_keys

        def initialize(object, request, context)
          @object = object
          request = request
          resource_klass = request.resource_klass
          @resource = resource_klass.new(object, context)

          # Need to reflect on object's associations for error reporting.
          @relationships     = resource_klass._relationships.values
          @relationship_keys = @relationships.map(&:name).map(&:to_sym)
          @foreign_keys      = @relationships.map(&:foreign_key).map(&:to_sym)
        end

        def errors
          object.errors.keys.map do |key|
            error_meta = {
              code: JSONAPI::VALIDATION_ERROR,
              status: :unprocessable_entity,
              title: object.errors.full_messages_for(key).first
            }

            # Determine if this is a foreign key, which will need to look up its
            # matching association name.
            is_foreign_key = foreign_keys.include?(key)
            id = is_foreign_key ? relationships.select { |r| r.foreign_key == key }.first.name : key
            id = id.to_sym

            key_formatter = JSONAPI.configuration.key_formatter
            error_meta[:id] = key_formatter.format(id).to_sym

            # Pointer should only be created for whitelisted attributes.
            if resource.fetchable_fields.include?(id) || key == :base
              error_meta[:source] = {}

              # Pointer depends on whether we're using an association, foreign
              # key, base, or attribute.
              error_meta[:source][:pointer] =
                # Relationship
                if is_foreign_key || relationship_keys.include?(id)
                  "/data/relationships/#{error_meta[:id]}"
                # Base
                elsif key == :base
                  '/data'
                # Attribute
                else
                  "/data/attributes/#{error_meta[:id]}"
                end
            end

            JSONAPI::Error.new(error_meta)
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
