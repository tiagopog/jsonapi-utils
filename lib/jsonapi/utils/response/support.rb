require 'jsonapi/utils/support/error'
require 'jsonapi/utils/support/filter/default'
require 'jsonapi/utils/support/pagination'
require 'jsonapi/utils/support/sort'

module JSONAPI
  module Utils
    module Response
      module Support
        include ::JSONAPI::Utils::Support::Error
        include ::JSONAPI::Utils::Support::Filter::Default
        include ::JSONAPI::Utils::Support::Pagination
        include ::JSONAPI::Utils::Support::Sort

        private

        def correct_media_type
          unless response.body.empty?
            response.headers['Content-Type'] = JSONAPI::MEDIA_TYPE
          end
        end
      end
    end
  end
end
