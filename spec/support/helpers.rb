require 'json'

module Helpers
  module ResponseParser
    def json
      @json ||= JSON.parse(response.body)
    end

    def error
      @error ||= json['errors'].first
    end

    def data
      @data ||= json['data']
    end

    def links
      @links ||= json['links']
    end

    def included
      @included ||= json['included']
    end

    def record_count
      @record_count ||= json['meta']['record_count']
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

    def has_included_relationships?(relationships)
      Array(data).all? do |record|
        record['relationships'].all? do |(key, relation)|
          return true if relation['data'].blank?
          relationship_ids = relation['data'].map { |e| e['id'] }
          (relationship_ids - included_ids[key]).empty?
        end
      end
    end

    def included_ids
      return false unless included.present?
      @included_ids ||= included.reduce({}) do |sum, record|
        sum.tap do |hash|
          if hash[record['type']].blank?
            hash[record['type']] = Array(record['id'])
          else
            hash[record['type']].push(record['id'])
          end
        end
      end
    end
  end
end
