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
        @request.errors.blank? || render_errors(@request.errors)
      end
    end
  end
end
