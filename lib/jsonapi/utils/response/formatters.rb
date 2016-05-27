module JSONAPI
  module Utils
    module Response
      module Formatters
        def jsonapi_format_errors(exception)
          JSONAPI::ErrorsOperationResult.new(exception.errors[0].code, exception.errors)
        end

        def jsonapi_serialize(records, options = {})
          if records.is_a?(Hash)
            hash    = records.with_indifferent_access
            records = hash_to_active_record(hash[:data], options[:model])
          end
          fix_request_options(params, records)
          build_response_document(records, options).contents
        end
      end
    end
  end
end
