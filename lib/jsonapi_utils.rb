require "jsonapi_utils/version"

# TODO:
# 1. Create a test suite;
# 2. Refactor and separate into submodules;
# 3. Include 'version' field in the meta node.
module JsonapiUtils
  extend ActiveSupport::Concern

  include do
    helper_method :jsonapi_serialize
  end

  # TODO:
  # 1. Make it work with nil values;
  def jsonapi_render(options)
    if options.has_key?(:json)
      response_body = jsonapi_serialize(options[:json], options[:options] || {})
      render json: response_body, status: (options[:status] || :ok)
    end
  end

  def jsonapi_serialize(records, options = {})
    fix_request_options(params, records)
    results = JSONAPI::OperationResults.new

    if records.respond_to?(:to_ary)
      records = fix_when_hash(records, options) if records.all? { |e| e.is_a?(Hash) }
      @resources = build_collection(records)
      results.add_result(JSONAPI::ResourcesOperationResult.new(:ok, @resources, result_options(options)))
    else
      @resource = turn_into_resource(records)
      results.add_result(JSONAPI::ResourceOperationResult.new(:ok, @resource))
    end

    create_response_document(results).contents
  end

  def jsonapi_error(exception)
    JSONAPI::ErrorsOperationResult.new(exception.errors[0].code, exception.errors).as_json
  end

  private

  def fix_request_options(params, records)
    return if request.method !~ /get/i ||
              params.nil? ||
              %w(index show create update destroy).include?(params[:action])
    action = records.respond_to?(:to_ary) ? 'index' : 'show'
    @request.send("setup_#{action}_action", params)
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
      options[:record_count] = count_records(@resources, options) if @paginator.class.requires_record_count
      return @paginator.links_page_params(options)
    else
      return {}
    end
  end


  def build_collection(records)
    return [] unless records.present?
    paginator(@request.params).apply(records, nil).map do |record|
      turn_into_resource(record)
    end
  end

  def turn_into_resource(record)
    @request.resource_klass.new(record)
  end

  # TODO:
  # 1. Make it work with OffsetPaginator;
  def paginator(params)
    PagedPaginator.new(ActionController::Parameters.new(params[:page]))
  end

  # TODO:
  # 1. Make it work for a single Hash;
  # 2. Change the primary key (for instance: uuid).
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

