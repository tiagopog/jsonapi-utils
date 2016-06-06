require 'jsonapi/utils/support/filter'
require 'jsonapi/utils/support/pagination'
require 'jsonapi/utils/support/sort'
require 'jsonapi/utils/support/error'

module JSONAPI
  module Utils
    module Response
      module Support
        include ::JSONAPI::Utils::Support::Error
        include ::JSONAPI::Utils::Support::Filter
        include ::JSONAPI::Utils::Support::Pagination
        include ::JSONAPI::Utils::Support::Sort

        protected

        def correct_media_type
          if response.body.size > 0
            response.headers['Content-Type'] = JSONAPI::MEDIA_TYPE
          end
        end
      end
    end
  end
end
