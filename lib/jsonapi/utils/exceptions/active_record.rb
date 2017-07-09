module JSONAPI
  module Utils
    module Exceptions
      class ActiveRecord < ::JSONAPI::Exceptions::Error
        attr_reader :object, :resource, :relationships, :relationship_names, :foreign_keys

        # Construct an error decorator over ActiveRecord objects.
        #
        # @param object [ActiveRecord::Base] Invalid ActiveRecord object.
        #   e.g.: User.new(name: nil).tap(&:save)
        #
        # @param resource_klass [JSONAPI::Resource] Resource class to be used for reflection.
        #   e.g.: UserResuource
        #
        # @return [JSONAPI::Utils::Exceptions::ActiveRecord]
        #
        # @api public
        def initialize(object, resource_klass, context)
          @object   = object
          @resource = resource_klass.new(object, context)

          # Need to reflect on resource's relationships for error reporting.
          @relationships      = resource_klass._relationships.values
          @relationship_names = @relationships.map(&:name).map(&:to_sym)
          @foreign_keys       = @relationships.map(&:foreign_key).map(&:to_sym)
          @resource_key_for  = {}
        end

        # Decorate errors from AR invalid objects.
        #
        # @note That's the method used by formatters to build the response's error body.
        #
        # @return [Array]
        #
        # @api public
        def errors
          object.errors.messages.flat_map do |field, messages|
            messages.map { |message| build_error(field, message) }
          end
        end

        private

        # Turn AR error into JSONAPI::Error.
        #
        # @param field [Symbol] Name of the invalid field
        #   e.g.: :title
        #
        # @param message [String] Error message
        #   e.g.: "can't be blank"
        #
        # @return [JSONAPI::Error]
        #
        # @api private
        def build_error(field, message)
          error = error_base
            .merge(
              id: id_member(field),
              title: message,
              detail: detail_member(field, message)
            ).merge(source_member(field))
          JSONAPI::Error.new(error)
        end

        # Build the "id" member value for the JSON API error object.
        #  e.g.: for :first_name => :"first-name"
        #
        # @note The returned value depends on the key formatter type defined
        #   via configuration: config.json_key_format = :dasherized_key
        #
        # @param field [Symbol] Name of the invalid field
        #   e.g.: :title
        #
        # @return [Symbol]
        #
        # @api private
        def id_member(field)
          @id_member ||= JSONAPI.configuration
            .key_formatter
            .format(resource_key_for(field))
            .to_sym
        end

        # Build the "source" member value for the JSON API error object.
        #  e.g.: :title => "/data/attributes/title"
        #
        # @param field [Symbol] Name of the invalid field
        #   e.g.: :title
        #
        # @return [Hash]
        #
        # @api private
        def source_member(field)
          resource_key = resource_key_for(field)
          return {} unless field == :base || resource.fetchable_fields.include?(resource_key)
          id = id_member(field)

          pointer =
            if field == :base                               then '/data'
            elsif relationship_names.include?(resource_key) then "/data/relationships/#{id}"
            else "/data/attributes/#{id}"
            end

          { source: { pointer: pointer } }
        end

        # Build the "detail" member value for the JSON API error object.
        #  e.g.: :first_name, "can't be blank" => "First name can't be blank"
        #
        # @param field [Symbol] Name of the invalid field
        #   e.g.: :first_name
        #
        # @return [String]
        #
        # @api private
        def detail_member(field, message)
          return message if field == :base
          resource_key = resource_key_for(field)
          [translation_for(resource_key), message].join(' ')
        end

        # Return the resource's attribute or relationship key name for a given field name.
        # e.g.: :title => :title, :user_id => :author
        #
        # @param field [Symbol] Name of the invalid field
        #   e.g.: :title
        #
        # @return [Symbol]
        #
        # @api private
        def resource_key_for(field)
          @resource_key_for[field] ||= begin
            return field unless foreign_keys.include?(field)
            relationships.find { |r| r.foreign_key == field }.name.to_sym
          end
        end

        # Turn the field name into human-friendly one.
        # e.g.: :first_name => "First name"
        #
        # @param field [Symbol] Name of the invalid field
        #   e.g.: :first_name
        #
        # @return [String]
        #
        # @api private
        def translation_for(field)
          object.class.human_attribute_name(field)
        end

        # Return the base data used for all errors of this kind.
        #
        # @return [Hash]
        #
        # @api private
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
