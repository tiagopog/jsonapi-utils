module JSONAPI
  module Utils
    module Support
      module Pagination
        module RecordCounter
          # mapping of record collenction types to classes responsible for counting them
          #
          # @api private
          @counter_mappings = {}

          class << self

            # Add a new counter class to the mappings hash
            #
            # @param counter_class [ < BaseCounter] class to register with RecordCounter
            #   e.g.: ActiveRecordCounter
            #
            # @api public
            def add(counter_class)
              @counter_mappings ||= {}
              @counter_mappings[counter_class.type] = counter_class
            end

            # Execute the appropriate counting call for a collection with controller params and opts
            #
            # @param records [ActiveRecord::Relation, Array] collection of records
            #   e.g.: User.all or [{ id: 1, name: 'Tiago' }, { id: 2, name: 'Doug' }]
            #
            # @param params [Hash] Rails params
            #
            # @param options [Hash] JU's options
            #   e.g.: { resource: V2::UserResource, count: 100 }
            #
            # @return [Integer]
            #   e.g.: 42
            #
            #@api public
            def count(records, params = {}, options = {})
              # Go through the counter types to see if there's a counter class that
              #   knows how to handle the current record set type
              @counter_mappings.each do |counted_class, counter_class|
                if records.is_a? counted_class
                  # counter class found; execute the call
                  return counter_class.new(records, params, options).count
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


              # Register the class with RecordCounter to let it know that this class
              # is responsible for counting the type
              #
              # @param @type: [String] snake_cased modultarized name of the record type the
              #     counter class is responsible for handling
              #   e.g.: 'arcive_record/relation'
              #
              # @api public
              def counts(type)
                self.type = type.camelize.constantize
                Rails.logger.info "Registered #{self} to count #{type.camelize}" if Rails.logger.present?
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
            def count
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