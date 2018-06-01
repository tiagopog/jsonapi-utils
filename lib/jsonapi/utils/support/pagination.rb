module JSONAPI
  module Utils
    module Support
      module Pagination
        RecordCountError = Class.new(ArgumentError)

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
          records.is_a?(Array) ? records[paginate_with(:range)] : paginate_with(:paginator).apply(records, nil)
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
          paginator.links_page_params(record_count: record_count_for(records, options))
        end

        # Apply memoization to the record count result avoiding duplicate counts.
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
        # @api public
        def record_count_for(records, options)
          @record_count ||= count_records(records, options)
        end

        private

        # Define the paginator object to be used in the response's pagination.
        #
        # @return [PagedPaginator, OffsetPaginator]
        #
        # @api private
        def paginator
          @paginator ||= paginator_klass.new(page_params)
        end

        # Return the paginator class to be used in the response's pagination.
        #
        # @return [Paginator]
        #
        # @api private
        def paginator_klass
          "#{JSONAPI.configuration.default_paginator}_paginator".classify.constantize
        end

        # Check whether pagination should be applied to the response.
        #
        # @return [Boolean]
        #
        # @api private
        def apply_pagination?(options)
          JSONAPI.configuration.default_paginator != :none &&
            (options[:paginate].nil? || options[:paginate])
        end

        # Creates an instance of ActionController::Parameters for page params.
        #
        # @return [ActionController::Parameters]
        #
        # @api private
        def page_params
          @page_params ||= begin
            page = @request.params.to_unsafe_hash['page'] || {}
            ActionController::Parameters.new(page)
          end
        end

        # Define the paginator or range according to the pagination strategy.
        #
        # @param kind [Symbol] pagination object's kind
        #   e.g.: :paginator or :range
        #
        # @return [PagedPaginator, OffsetPaginator, Range]
        #   e.g.: #<PagedPaginator:0x00561ed06dc5a0 @number=1, @size=2>
        #         0..9
        #
        # @api private
        def paginate_with(kind)
          @pagination ||=
            case kind
            when :paginator then paginator
            when :range     then pagination_range
            end
        end

        # Define a pagination range for objects which quack like Arrays.
        #
        # @return [Range]
        #   e.g.: 0..9
        #
        # @api private
        def pagination_range
          case JSONAPI.configuration.default_paginator
          when :paged
            number = page_params['number'].to_i.nonzero? || 1
            size   = page_params['size'].to_i.nonzero?   || JSONAPI.configuration.default_page_size
            (number - 1) * size..number * size - 1
          when :offset
            offset = page_params['offset'].to_i.nonzero? || 0
            limit  = page_params['limit'].to_i.nonzero?  || JSONAPI.configuration.default_page_size
            offset..offset + limit - 1
          else
            paginator.pagination_range(page_params)
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
          return options[:count].to_i if options[:count].is_a?(Numeric)

          RecordCounter.count( records, params, options )
        end

        # Count pages in order to build a proper pagination and to fill up the "page_count" response's member.
        #
        # @param record_count [Integer] number of records
        #   e.g.: 42
        #
        # @return [Integer]
        #   e.g 5
        #
        # @api private
        def page_count_for(record_count)
          return 0 if record_count.to_i < 1

          size = (page_params['size'] || page_params['limit']).to_i
          size = JSONAPI.configuration.default_page_size if size.zero?
          (record_count.to_f / size).ceil
        end

        module RecordCounter
          @counter_mappings = {}

          class << self

            def add(counter_class)
              @counter_mappings ||= {}
              @counter_mappings[counter_class.type] = counter_class
            end

            def count(records, params = {}, options = {})
              @counter_mappings.each do |counted_class, counter_class|
                if records.is_a? counted_class
                  return counter_class.new(records, options).count
                end
              end

              raise RecordCountError, "Can't count records with the given options"
            end
          end

          class BaseCounter
            attr_accessor :records, :params, :options

            def initialize(records, params = {}, options = {})
              @records = records
              @params  = params
              @options = options
            end

            class << self

              attr_accessor :type

              def counts(type)
                self.type = type.camelize.constantize
                RecordCounter.add self
              rescue NameError
                Rails.logger.warn "Unable to register #{self}: uninitialized constant #{type.camelize}" if Rails.logger.present?
              end
            end
          end

          class ArrayCounter < BaseCounter
            counts "array"

            delegate :count, to: :records
          end


          class ActiveRecordCounter < BaseCounter
            counts "active_record/relation"

            # Count records from the datatase applying the given request filters
            # and skipping things like eager loading, grouping and sorting.
            #
            # @records [ActiveRecord::Relation, Array] collection of records
            #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
            #
            # @options [Hash] JU's options
            #   e.g.: { resource: V2::UserResource, count: 100 }
            #
            # @return [Integer]
            #   e.g.: 42
            #
            # @api private
            def count
              @records = apply_filter(records, options) if params[:filter].present?
              count   = -> (records, except:) do
                records.except(*except).count(distinct_count_sql(records))
              end
              count.(@records, except: %i(includes group order))
            rescue ActiveRecord::StatementInvalid
              count.(@records, except: %i(group order))
            end

            # Build the SQL distinct count with some reflection on the "records" object.
            #
            # @param records [ActiveRecord::Relation] collection of records
            #   e.g.: User.all
            #
            # @return [String]
            #   e.g.: "DISTINCT users.id"
            #
            # @api private
            def distinct_count_sql(records)
              "DISTINCT #{records.table_name}.#{records.primary_key}"
            end
          end
        end
      end
    end
  end
end
