module JSONAPI
  module Utils
    module Response
      module Formatters
        def jsonapi_format(records, options = {})
          if records.is_a?(Hash)
            hash    = records.with_indifferent_access
            records = hash_to_active_record(hash[:data], options[:model])
          end
          fix_request_options(params, records)
          build_response_document(records, options).contents
        end

        alias_method :jsonapi_serialize, :jsonapi_format

        def jsonapi_format_errors(data)
          data = JSONAPI::Utils::Exceptions::ActiveRecord.new(data, @request.resource_klass, context) if active_record_obj?(data)
          errors = data.respond_to?(:errors) ? data.errors : data
          JSONAPI::Utils::Support::Error.sanitize(errors).uniq
        end

        private

        def active_record_obj?(data)
          data.is_a?(ActiveRecord::Base)|| data.singleton_class.include?(ActiveModel::Model)
        end

        def build_response_document(records, options)
          results = JSONAPI::OperationResults.new

          if records.respond_to?(:to_ary)
            @_records = build_collection(records, options)
            results.add_result(JSONAPI::ResourcesOperationResult.new(:ok, @_records, result_options(records, options)))
          else
            @_record = turn_into_resource(records, options)
            results.add_result(JSONAPI::ResourceOperationResult.new(:ok, @_record))
          end

          @_response_document = create_response_document(results)
        end

        def fix_request_options(params, records)
          return if request.method !~ /get/i ||
                    params.nil? ||
                    %w(index show create update destroy).include?(params[:action])
          action = records.respond_to?(:to_ary) ? 'index' : 'show'
          @request.send("setup_#{action}_action", params)
        end

        def result_options(records, options)
          {}.tap do |data|
            if JSONAPI.configuration.default_paginator != :none &&
              JSONAPI.configuration.top_level_links_include_pagination
              data[:pagination_params] = pagination_params(records, options)
            end

            if JSONAPI.configuration.top_level_meta_include_record_count
              data[:record_count] = count_records(records, options)
            end
          end
        end

        def build_collection(records, options = {})
          records = apply_filter(records, options)
          records = apply_pagination(records, options)
          records = apply_sort(records)
          records.respond_to?(:to_ary) ? records.map { |record| turn_into_resource(record, options) } : []
        end

        def turn_into_resource(record, options = {})
          if options[:resource]
            options[:resource].to_s.constantize.new(record, context)
          else
            @request.resource_klass.new(record, context)
          end
        end

        def hash_to_active_record(data, model)
          return data if model.nil?
          coerced = [data].flatten.map { |hash| model.new(hash) }
          data.is_a?(Array) ? coerced : coerced.first
        rescue ActiveRecord::UnknownAttributeError
          if data.is_a?(Array)
            ids = data.map { |e| e[:id] }
            model.where(id: ids)
          else
            model.find_by(id: data[:id])
          end
        end
      end
    end
  end
end
