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
        unless @request.operations.empty?
          operation = @request.operations.find { |e| e.data[:attributes].present? }
          operation.nil? ? {} : operation.data[:attributes]
        end
      end
    end
  end
end
