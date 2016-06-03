require 'jsonapi/utils/support/filter'
require 'jsonapi/utils/support/pagination'
require 'jsonapi/utils/support/sort'
require 'jsonapi/utils/support/render'

module JSONAPI
  module Utils
    module Response
      module Support
        include ::JSONAPI::Utils::Support::Filter
        include ::JSONAPI::Utils::Support::Pagination
        include ::JSONAPI::Utils::Support::Sort
        include ::JSONAPI::Utils::Support::Render
      end
    end
  end
end
