module JSONAPI
  module Utils
    module Support
      module Pagination
        # Apply proper pagination to the records.
        #
        # @param records [ActiveRecord::Relation, Array] collection of records
        #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
        #
        # @param options [Hash] JU's options
        #   e.g.: { resource: V2::UserResource, count: 100 }
        #
        # @return [ActiveRecord::Relation, Array]
        #
        # @api public
        def apply_pagination(records, options = {})
          return records unless apply_pagination?(options)
          records.is_a?(Array) ? records[pagination[:range]] : pagination[:paginator].apply(records, nil)
        end

        # Mount pagination params for JSONAPI::ResourcesOperationResult.
        # It can also be used anywhere else as a helper method.
        #
        # @param records [ActiveRecord::Relation, Array] collection of records
        #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
        #
        # @param options [Hash] JU's options
        #   e.g.: { resource: V2::UserResource, count: 100 }
        #
        # @return [Hash]
        #   e.g.: {"first"=>{"number"=>1, "size"=>2}, "next"=>{"number"=>2, "size"=>2}, "last"=>{"number"=>2, "size"=>2}}
        #
        # @api public
        def pagination_params(records, options)
          return {} unless JSONAPI.configuration.top_level_links_include_pagination
          paginator.links_page_params(record_count: count_records(records, options))
        end

        private

        # Define the paginator object to be used in the response's pagination.
        #
        # @return [PagedPaginator, OffsetPaginator]
        #
        # @api private
        def paginator
          @paginator ||=
            if JSONAPI.configuration.default_paginator == :paged
              PagedPaginator.new(page_params)
            elsif JSONAPI.configuration.default_paginator == :offset
              OffsetPaginator.new(page_params)
            end
        end

        # Check whether pagination should be applied to the response.
        #
        # @return [Boolean]
        #
        # @api private
        def apply_pagination?(options)
          JSONAPI.configuration.default_paginator != :none && (options[:paginate].nil? || options[:paginate])
        end

        # Creates an instance of ActionController::Parameters for page params.
        #
        # @return [ActionController::Parameters]
        #
        # @api private
        def page_params
          @page_params ||= ActionController::Parameters.new(@request.params[:page] || {})
        end

        # Define the paginator and range according to the pagination strategy.
        #
        # @return [Hash]
        #   e.g.: {:paginator=>#<PagedPaginator:0x00561ed06dc5a0 @number=1, @size=2>, :range=>0..1}
        #
        # @api private
        def pagination
          @pagination ||=
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

        # Count records in order to build a proper pagination and to fill up the "record_count" response's member.
        #
        # @param records [ActiveRecord::Relation, Array] collection of records
        #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
        #
        # @param options [Hash] JU's options
        #   e.g.: { resource: V2::UserResource, count: 100 }
        #
        # @return [Integer]
        #   e.g.: 42
        #
        # @api private
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
