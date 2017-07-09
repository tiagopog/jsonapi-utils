module JSONAPI
  module Utils
    module Exceptions
      class ActiveRecord < ::JSONAPI::Exceptions::Error
        attr_reader :object, :resource, :relationships, :relationship_types, :foreign_keys

        def initialize(object, resource_klass, context)
          @object   = object
          @resource = resource_klass.new(object, context)

          # Need to reflect on resource's relationships for error reporting.
          @relationships      = resource_klass._relationships.values
          @relationship_types = @relationships.map(&:name).map(&:to_sym)
          @foreign_keys       = @relationships.map(&:foreign_key).map(&:to_sym)
        end

        def errors
          object.errors.messages.flat_map do |key, messages|
            messages.map { |message| build_error(key, message) }
          end
        end

        private

        def build_error(key, message)
          error = error_base
            .merge(
              id: id_member(key),
              title: message,
              detail: detail_member(key, message)
              ).merge(source_member(key))
          JSONAPI::Error.new(error)
        end

        def id_member(key)
          @id_member ||= JSONAPI.configuration
            .key_formatter
            .format(resource_key_for(key))
            .to_sym
        end

        # Determine if this is a foreign key, which will need to look up its
        # matching association name.
        def resource_key_for(key)
          return key unless foreign_keys.include?(key)
          relationships.find { |r| r.foreign_key == key }.name.to_sym
        end

        def source_member(key)
          Hash.new.tap do |hash|
            resource_key = resource_key_for(key)

            # Pointer should only be created for whitelisted attributes.
            return hash unless resource.fetchable_fields.include?(resource_key) || key == :base

            id = id_member(key)

            hash[:source] = {}
            hash[:source][:pointer] =
              # Relationship
              if relationship_types.include?(resource_key)
                "/data/relationships/#{id}"
              # Base
              elsif key == :base
                '/data'
              # Attribute
              else
                "/data/attributes/#{id}"
              end
          end
        end

        def detail_member(key, message)
          if key == :base
            message
          else
            resource_key = resource_key_for(key)
            [translation_for(resource_key), message].join(' ')
          end
        end

        def translation_for(key)
          object.class.human_attribute_name(key)
        end

        def error_base
          {
            code: JSONAPI::VALIDATION_ERROR,
            status: :unprocessable_entity
          }
        end
      end
    end
  end
end
