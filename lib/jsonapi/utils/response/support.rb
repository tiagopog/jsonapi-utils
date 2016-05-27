require 'jsonapi/utils/support/filter'
require 'jsonapi/utils/support/pagination'
require 'jsonapi/utils/support/sort'

module JSONAPI
  module Utils
    module Response
      module Support
        include ::JSONAPI::Utils::Support::Filter
        include ::JSONAPI::Utils::Support::Pagination
        include ::JSONAPI::Utils::Support::Sort
      end
    end
  end
end
