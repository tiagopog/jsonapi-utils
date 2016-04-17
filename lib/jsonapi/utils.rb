require 'jsonapi/utils/version'
require 'active_support/concern'
require 'jsonapi/utils/exceptions'

module JSONAPI
  module Utils
    extend ::ActiveSupport::Concern

    include do
      helper_method :jsonapi_serialize
    end

    def jsonapi_render(options)
      if options.has_key?(:json)
        response = jsonapi_serialize(options[:json], options[:options] || {})
        render json: response, status: options[:status] || :ok
      else
        raise ArgumentError.new('":json" key must be set to JSONAPI::Utils#jsonapi_render')
      end
    rescue => e
      raise e unless e.class.name.starts_with?('JSONAPI::Exceptions')
      handle_exceptions(e)
    ensure
      headers['Content-Type'] = JSONAPI::MEDIA_TYPE
    end

    def jsonapi_render_errors(exception)
      error = jsonapi_format_errors(exception)
      render json: { errors: error.errors }, status: error.code
    end

    def jsonapi_format_errors(exception)
      JSONAPI::ErrorsOperationResult.new(exception.errors[0].code, exception.errors)
    end

    def jsonapi_render_internal_server_error
      jsonapi_render_errors(::JSONAPI::Utils::Exceptions::InternalServerError.new)
    end

    def jsonapi_render_bad_request
      jsonapi_render_errors(::JSONAPI::Utils::Exceptions::BadRequest.new)
    end

    def jsonapi_render_not_found(exception)
      id = exception.message.match(/=([\w-]+)/)[1]
      jsonapi_render_errors(JSONAPI::Exceptions::RecordNotFound.new(id))
    end

    def jsonapi_render_not_found_with_null
      render json: { data: nil }, status: 200
    end

    def jsonapi_serialize(records, options = {})
      setup_request
      results = JSONAPI::OperationResults.new

      fix_request_options(params, records)

      if records.respond_to?(:to_ary)
        records = fix_when_hash(records, options) if needs_to_be_fixed?(records)
        @_records = build_collection(records, options)
        results.add_result(JSONAPI::ResourcesOperationResult.new(:ok, @_records, result_options(records, options)))
      else
        @_record = turn_into_resource(records, options)
        results.add_result(JSONAPI::ResourceOperationResult.new(:ok, @_record))
      end

      create_response_document(results).contents
    end

    private

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
      page_params = ActionController::Parameters.new(params[:page])

      @paginator ||=
        if JSONAPI.configuration.default_paginator == :paged
          PagedPaginator.new(page_params)
        elsif JSONAPI.configuration.default_paginator == :offset
          OffsetPaginator.new(page_params)
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

    def apply_filter(records, options = {})
      if apply_filter?(records, options)
        records.where(filter_params)
      else
        records
      end
    end

    def apply_filter?(records, options = {})
      params[:filter].present? && records.respond_to?(:where) &&
        (options[:filter].nil? || options[:filter])
    end

    def filter_params
      @_filter_params ||=
        params[:filter].keys.each_with_object({}) do |resource, hash|
          hash[resource] = params[:filter][resource]
        end
    end

    def apply_pagination(records, options = {})
      return records unless apply_pagination?(options)
      pagination = set_pagination(options)

      records =
        if records.is_a?(Array)
          records[pagination[:range]]
        else
          pagination[:paginator].apply(records, nil)
        end
    end

    def apply_sort(records)
      return records unless params[:sort].present?

      if records.is_a?(Array)
        records.sort { |a, b| comp = 0; eval(sort_criteria) }
      elsif records.respond_to?(:order)
        records.order(sort_params)
      end
    end

    def sort_criteria
      sort_params.reduce('') do |sum, hash|
        foo = ["a[:#{hash[0]}]", "b[:#{hash[0]}]"]
        foo.reverse! if hash[1] == :desc
        sum + "comp = comp == 0 ? #{foo.join(' <=> ')} : comp; "
      end
    end

    def sort_params
      @_sort_params ||=
        params[:sort].split(',').each_with_object({}) do |criteria, hash|
          order, field = criteria.match(/(\-?)(\w+)/i)[1..2]
          hash[field]  = order == '-' ? :desc : :asc
        end
    end

    def set_pagination(options)
      page_params = ActionController::Parameters.new(@request.params[:page])
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

    def apply_pagination?(options)
      JSONAPI.configuration.default_paginator != :none &&
        (options[:paginate].nil? || options[:paginate])
    end

    def fix_when_hash(records, options)
      return [] unless options[:model]
      records.map { |hash| options[:model].new(hash) }
    rescue ActiveRecord::UnknownAttributeError
      ids = records.map { |e| e[:id] || e['id'] }
      scope = options[:scope] ? options[:model].send(options[:scope]) : options[:model]
      scope.where(id: ids)
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

    def setup_request
      @request ||=
        JSONAPI::Request.new(
          params,
          context: context,
          key_formatter: key_formatter,
          server_error_callbacks: (self.class.server_error_callbacks || [])
        )
    end
  end
end
