module JSONAPI
  module Utils
    module Request
      def jsonapi_request_handling
        setup_request
        check_request
      end

      def setup_request
        @request ||=
          JSONAPI::RequestParser.new(
            params.dup,
            context: context,
            key_formatter: key_formatter,
            server_error_callbacks: (self.class.server_error_callbacks || [])
          )
      end

      def check_request
        @request.errors.blank? || jsonapi_render_errors(json: @request)
      end

      def resource_params
        build_params_for(:resource)
      end

      def relationship_params
        build_params_for(:relationship)
      end

      private

      def build_params_for(param_type)
        return {} if @request.operations.empty?

        keys      = %i(attributes to_one to_many)
        # not sure what this does but it essentially just makes operation equivalent to
        # @request.operations
        operation = @request.operations.find { |e| e.options[:data].keys & keys == keys }
        if operation.nil?
          {}
        elsif param_type == :relationship
          operation.options[:data].values_at(:to_one, :to_many).compact.reduce(&:merge)
        else
          operation.options[:data][:attributes]
        end
      end
    end
  end
end
