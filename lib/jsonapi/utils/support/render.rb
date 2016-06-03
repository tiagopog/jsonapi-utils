module JSONAPI
  module Utils
    module Support
      module Render
        module_function

        def get_error_hash(object)
          return {} unless object.respond_to?(:errors)
          object.errors.map do |error|
            keys = %i(title detail id code source links  status meta)
            keys.reduce({}) do |sum, key|
              value = error.send(key)
              if value.nil?
                sum
              else
                value = value.to_s if key == :code
                sum.merge(key => value)
              end
            end
          end
        end
      end
    end
  end
end
