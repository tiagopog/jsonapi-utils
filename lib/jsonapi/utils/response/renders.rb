module JSONAPI
  module Utils
    module Response
      module Renders
        # Helper method to render JSON API-compliant responses.
        #
        # @param json [ActiveRecord::Base, ActiveRecord::Relation, Hash, Array<Hash>]
        #   Object to be serialized into JSON
        #   e.g.: User.first, User.all, { data: { id: 1, first_name: 'Tiago' } },
        #   [{ data: { id: 1, first_name: 'Tiago' } }]
        #
        # @param status [Integer, String, Symbol] HTTP status code
        #   e.g.: 201, '201', :created
        #
        # @option options [JSONAPI::Resource] resource: it tells the render which resource
        #   class to be used rather than use an infered one (default behaviour)
        # 
        # @option options [JSONAPI::Resource] source_resource: it tells the render that this response is from a related resource
        #
        # @option options [JSONAPI::Resource] relationship_type: it tells that the render which relationship the data is from
        #
        # @option options [ActiveRecord::Base] model: ActiveRecord model class to be instantiated
        #   when a Hash or Array of Hashes is passed to the "json" key argument
        #
        # @option options [Integer] count: if it's rendering a collection of resources, the default
        #   gem's counting method can be bypassed by the use of this options. It's shows then the total
        #   records resulting from that request and also calculates the pagination.
        #
        # @return [String]
        #
        # @api public
        def jsonapi_render(json:, status: nil, options: {})
          body = jsonapi_format(json, options)
          render json: body, status: (status || @_response_document.status)
        rescue => e
          handle_exceptions(e) # http://bit.ly/2sEEGTN
        ensure
          correct_media_type
        end

        # Helper method to render JSON API-compliant error responses.
        #
        # @param error [ActiveRecord::Base or any object that responds to #errors]
        #   Error object to be serialized into JSON
        #   e.g.: User.new(name: nil).tap(&:save), MyErrorDecorator.new(invalid_object)
        #
        # @param json [ActiveRecord::Base or any object that responds to #errors]
        #   Error object to be serialized into JSON
        #   e.g.: User.new(name: nil).tap(&:save), MyErrorDecorator.new(invalid_object)
        #
        # @param status [Integer, String, Symbol] HTTP status code
        #   e.g.: 422, '422', :unprocessable_entity
        #
        # @return [String]
        #
        # @api public
        def jsonapi_render_errors(error = nil, json: nil, status: nil)
          body   = jsonapi_format_errors(error || json)
          status = status || body.try(:first).try(:[], :status) || :bad_request
          render json: { errors: body }, status: status
        ensure
          correct_media_type
        end

        # Helper method to render HTTP 500 Interval Server Error.
        #
        # @api public
        def jsonapi_render_internal_server_error
          jsonapi_render_errors(::JSONAPI::Utils::Exceptions::InternalServerError.new)
        end

        # Helper method to render HTTP 400 Bad Request.
        #
        # @api public
        def jsonapi_render_bad_request
          jsonapi_render_errors(::JSONAPI::Utils::Exceptions::BadRequest.new)
        end

        # Helper method to render HTTP 404 Bad Request.
        #
        # @api public
        def jsonapi_render_not_found(exception)
          id = exception.message =~ /=([\w-]+)/ && $1 || '(no identifier)'
          jsonapi_render_errors(JSONAPI::Exceptions::RecordNotFound.new(id))
        end

        # Helper method to render HTTP 404 Bad Request with null "data".
        #
        # @api public
        def jsonapi_render_not_found_with_null
          render json: { data: nil }, status: 200
        end
      end
    end
  end
end
