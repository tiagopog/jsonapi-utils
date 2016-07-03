module JSONAPI
  module Utils
    module Request
      def setup_request
        @request ||=
          JSONAPI::Request.new(
            params,
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
        operation = @request.operations.find { |e| e.data.keys & keys == keys }

        if operation.nil?
          {}
        elsif param_type == :relationship
          operation.data.values_at(:has_one, :to_many).compact.reduce(&:merge)
        else
          operation.data[:attributes]
        end
      end
    end
  end
end
