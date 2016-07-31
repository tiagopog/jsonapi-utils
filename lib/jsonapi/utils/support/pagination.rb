module JSONAPI
  module Utils
    module Support
      module Pagination
        def apply_pagination(records, options = {})
          return records unless apply_pagination?(options)

          pagination = set_pagination

          records =
            if records.is_a?(Array)
              records[pagination[:range]]
            else
              pagination[:paginator].apply(records, nil)
            end
        end

        def apply_pagination?(options)
          JSONAPI.configuration.default_paginator != :none &&
            (options[:paginate].nil? || options[:paginate])
        end

        def pagination_params(records, options)
          @paginator ||= paginator(params)
          if @paginator && JSONAPI.configuration.top_level_links_include_pagination
            options = {}
            @paginator.class.requires_record_count &&
              options[:record_count] = count_records(records, options)
            @paginator.links_page_params(options)
          else
            {}
          end
        end

        def paginator(params)
          page_params = ActionController::Parameters.new(params[:page] || {})

          @paginator ||=
            if JSONAPI.configuration.default_paginator == :paged
              PagedPaginator.new(page_params)
            elsif JSONAPI.configuration.default_paginator == :offset
              OffsetPaginator.new(page_params)
            end
        end

        def set_pagination
          page_params = ActionController::Parameters.new(@request.params[:page] || {})
          if JSONAPI.configuration.default_paginator == :paged
            @_paginator ||= PagedPaginator.new(page_params)
            number = page_params['number'].to_i.nonzero? || 1
            size   = page_params['size'].to_i.nonzero?   || JSONAPI.configuration.default_page_size
            { paginator: @_paginator, range: (number - 1) * size..number * size - 1 }
          elsif JSONAPI.configuration.default_paginator == :offset
            @_paginator ||= OffsetPaginator.new(page_params)
            offset = page_params['offset'].to_i.nonzero? || 0
            limit  = page_params['limit'].to_i.nonzero?  || JSONAPI.configuration.default_page_size
            { paginator: @_paginator, range: offset..offset + limit - 1 }
          else
            {}
          end
        end

        def count_records(records, options)
          if options[:count].present?
            options[:count]
          elsif records.is_a?(Array)
            records.length
          else
            records = apply_filter(records, options) if params[:filter].present?
            records.except(:group, :order).count("DISTINCT #{records.table.name}.id")
          end
        end
      end
    end
  end
end
