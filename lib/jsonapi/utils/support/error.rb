module JSONAPI
  module Utils
    module Support
      module Error
        MEMBERS = %i(title detail id code source links status meta)

        module_function

        def sanitize(errors)
          Array(errors).map do |error|
            MEMBERS.reduce({}) do |sum, key|
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
