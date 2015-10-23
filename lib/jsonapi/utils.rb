require 'jsonapi/utils/version'
require 'jsonapi/utils/exceptions'

module JSONAPI
  module Utils
    extend ActiveSupport::Concern

    include do
      helper_method :jsonapi_serialize
    end

    def jsonapi_render(options)
      if options.has_key?(:json)
        response = build_response(options)
        render json: response[:body], status: options[:status] || response[:status] || :ok
      end
    end

    def jsonapi_render_not_found
      jsonapi_render json: nil
    end

    def jsonapi_render_not_found_with_null
      jsonapi_render json: nil, options: { allow_null: true }
    end

    def jsonapi_serialize(records, options = {})
      return build_nil if records.nil? && options[:allow_null]
      results = JSONAPI::OperationResults.new

      if records.nil?
        id = extract_ids(@request.params)
        record_not_found = JSONAPI::Exceptions::RecordNotFound.new(id)
        results.add_result(JSONAPI::ErrorsOperationResult.new(record_not_found.errors[0].code, record_not_found.errors))
      else
        fix_request_options(params, records)

        if records.respond_to?(:to_ary)
          records = fix_when_hash(records, options) if needs_to_be_fixed?(records)
          @resources = build_collection(records, options)
          results.add_result(JSONAPI::ResourcesOperationResult.new(:ok, @resources, result_options(options)))
        else
          @resource = turn_into_resource(records, options)
          results.add_result(JSONAPI::ResourceOperationResult.new(:ok, @resource))
        end
      end

      create_response_document(results).contents
    end

    def jsonapi_bad_request
      jsonapi_error(::JSONAPI::Utils::Exceptions::BadRequest.new)
    end

    def jsonapi_internal_server_error
      jsonapi_error(::JSONAPI::Utils::Exceptions::InternalServerError.new)
    end

    def jsonapi_error(exception)
      JSONAPI::ErrorsOperationResult.new(exception.errors[0].code, exception.errors).as_json
    end

    private

    def build_response(options)
      {
        body: jsonapi_serialize(options[:json], options[:options] || {}),
        status: options[:json].nil? && !options[:allow_null] ? :not_found : :ok
      }
    end

    def build_nil
      { data: nil }
    end

    def extract_ids(hash)
      ids = hash.keys.select { |e| e =~ /id$/i }.map { |e| hash[e] }
      ids.first rescue '(id not identified)'
    end

    def fix_request_options(params, records)
      return if request.method !~ /get/i ||
                params.nil? ||
                %w(index show create update destroy).include?(params[:action])
      action = records.respond_to?(:to_ary) ? 'index' : 'show'
      @request.send("setup_#{action}_action", params)
    end

    def needs_to_be_fixed?(records)
      records.is_a?(Array) && records.all? { |e| e.is_a?(Hash) }
    end

    def result_options(options)
      hash = {}

      if JSONAPI.configuration.top_level_links_include_pagination
        hash[:pagination_params] = pagination_params(options)
      end

      if JSONAPI.configuration.top_level_meta_include_record_count
        hash[:record_count] = count_records(@resources, options)
      end

      hash
    end

    def pagination_params(options)
      @paginator ||= paginator(params)
      if @paginator && JSONAPI.configuration.top_level_links_include_pagination
        options = {}
        @paginator.class.requires_record_count &&
          options[:record_count] = count_records(@resources, options)
        return @paginator.links_page_params(options)
      else
        return {}
      end
    end

    def build_collection(records, options = {})
      return [] if records.nil? || records.empty?
      JSONAPI.configuration.default_paginator == :none ||
        records = paginator(@request.params).apply(records, nil)
      records.map { |record| turn_into_resource(record, options) }
    end

    def turn_into_resource(record, options = {})
      if options[:resource]
        options[:resource].to_s.constantize.new(record)
      else
        @request.resource_klass.new(record)
      end
    end

    def paginator(params)
      page_params = ActionController::Parameters.new(params[:page])

      @paginator ||=
        if JSONAPI.configuration.default_paginator == :paged
          PagedPaginator.new(page_params)
        elsif JSONAPI.configuration.default_paginator == :offset
          OffsetPaginator.new(page_params)
        end
    end

    def fix_when_hash(records, options)
      return [] unless options[:model]
      records.map { |hash| options[:model].new(hash) }
    rescue
      ids = records.map { |e| e[:id] || e['id'] }
      scope = options[:scope] ? options[:model].send(options[:scope]) : options[:model]
      scope.where(id: ids)
    end

    def count_records(records, options)
      if records.size.zero? then 0
      elsif options[:count] then options[:count]
      elsif options[:model] && options[:scope] then options[:model].send(options[:scope]).count
      elsif options[:model] then options[:model].count
      else records.first.model.class.count
      end
    end
  end
end
