class CustomOffsetPaginator < OffsetPaginator
  def pagination_range(page_params)
    offset = page_params['offset'].to_i.nonzero? || 0
    limit  = page_params['limit'].to_i.nonzero?  || JSONAPI.configuration.default_page_size
    offset..offset + limit - 1
  end
end


class BogusCounter < JSONAPI::Utils::Support::Pagination::RecordCounter::BaseCounter
  counts "junk"
end

class StringCounter < JSONAPI::Utils::Support::Pagination::RecordCounter::BaseCounter
  counts "string"

  def count
    @records.length
  end
end