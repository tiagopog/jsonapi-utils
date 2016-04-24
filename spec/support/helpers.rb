require 'json'

module Helpers
  module ResponseParser
    def json
      @json ||= JSON.parse(response.body)
    end

    def data
      @data ||= json['data']
    end

    def links
      @links ||= json['links']
    end

    def error
      @error ||= json['errors'].first
    end

    def has_fetchable_fields?(fields)
      Array(data).all? { |record| record['attributes'].keys == fields }
    end

    def has_valid_id_and_type_members?(type)
      Array(data).all? do |record|
        record['id'].present? && record['type'] == type
      end
    end

    def has_relationship_members?(relationships)
      Array(data).all? { |record| record['relationships'].keys == relationships }
    end
  end
end
