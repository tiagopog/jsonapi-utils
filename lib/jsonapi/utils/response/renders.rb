require 'pry'

module JSONAPI
  module Utils
    module Response
      module Renders
        def jsonapi_render(json:, status: nil, options: {})
          body = jsonapi_serialize(json, options)
          render json: body, status: status || @_response_document.status
        rescue => e
          handle_exceptions(e)
        ensure
          if response.body.size > 0
            response.headers['Content-Type'] = JSONAPI::MEDIA_TYPE
          end
        end

        def jsonapi_render_errors(exception)
          result = jsonapi_format_errors(exception)
          errors = JSONAPI::Utils::Support::Render.get_error_hash(result)
          render json: { errors: errors }, status: errors[0][:status]
        end

        def jsonapi_render_internal_server_error
          jsonapi_render_errors(::JSONAPI::Utils::Exceptions::InternalServerError.new)
        end

        def jsonapi_render_bad_request
          jsonapi_render_errors(::JSONAPI::Utils::Exceptions::BadRequest.new)
        end

        def jsonapi_render_not_found(exception)
          id = exception.message.match(/=([\w-]+)/).try(:[], 1) || '(no identifier)'
          jsonapi_render_errors(JSONAPI::Exceptions::RecordNotFound.new(id))
        end

        def jsonapi_render_not_found_with_null
          render json: { data: nil }, status: 200
        end
      end
    end
  end
end
