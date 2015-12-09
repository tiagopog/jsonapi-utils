##
# Requests
##

shared_examples_for 'JSON API request' do |options|
  let(:headers) do
    { 'Accept' => 'application/vnd.api+json' }
  end

  let(:params) do
    local_params = options.try(:params) || {}
    options[:action] == :show ? local_params.merge!(options[:record]) : local_params
  end

  before(:each) { expect(response).to have_http_status 200 }

  def data
    json['data'].is_a?(Array) ? json['data'] : [json['data']]
  end

  it_behaves_like 'default request', options
  it_behaves_like 'request with query string', options
end

shared_examples_for 'default request' do |options|
  context 'default request' do
    subject(:response) do
      get options[:action], params, headers
    end

    it_behaves_like 'base top-level nodes', options
  end
end

shared_examples_for 'request with query string' do |options|
  include_context 'with "fields" param', options
  include_context 'with "include" param', options
  include_context 'with "page" param', options if options[:actions] == :index
end

shared_examples_for 'JSON for collections' do |options|
  options.merge!({ action: :index, count: 3 })
  it_behaves_like 'JSON API request', options
end

shared_examples_for 'JSON for collections with error' do
  it_behaves_like 'request with error', action: :index
end

shared_examples_for 'JSON for a single record' do |options|
  options.merge!({ action: :show, record: { id: 1 } })
  it_behaves_like 'JSON API request', options
end

shared_examples_for 'JSON for a single record with error' do
  it_behaves_like 'request with error', { action: :show, record: { id: 9999 } }
end

##
# JSON API's top-level nodes
##

shared_examples_for 'base top-level nodes' do |options|
  it 'has the "data" field' do
    expect(data).to be_present
  end

  it 'has the "id" field' do
    all_ok = data.all? { |e| e['id'].present? }
    expect(all_ok).to be_truthy
  end

  it 'has the "attributes" field' do
    all_ok = data.all? { |e| e['attributes'].present? }
    expect(all_ok).to be_truthy
  end

  it "returns a collection of #{options[:resource]}" do
    all_ok = data.all? { |e| e['type'] == options[:resource].to_s }
    expect(all_ok).to be_truthy
  end
end

##
# Query string params
##

shared_context 'with "fields" param' do |options|
  it 'returns only the listed fields' do
    field = options[:fields].try(:sample) || options[:fields]
    fields = { "#{options[:resource]}": field }

    params.merge!({ fields: fields })
    get options[:action], params, headers

    expect(data[0]['attributes'].keys).to include_items(field.to_s)
  end
end

shared_context 'with "include" param' do |options|
  let(:nested) { options[:include].sample.to_s }

  def get_with_include(options)
    params.merge!({ include: nested })
    get options[:action], params, headers
  end

  it 'returns the listed nested resources' do
    get_with_include(options)
    all_ok = json['included'].all? { |e| e['type'] == nested }
    expect(all_ok).to be_truthy
  end

  it 'includes the "self" and "related" links in "relationships"' do
    get_with_include(options)
    links = data[0]['relationships'][nested]['links']
    expect(links['self']).to be_present
    expect(links['related']).to be_present
  end
end

shared_context 'with "page" param' do |options|
  let(:size) { 1 }

  def get_with_pagination(options, size = 1, number = 1)
    params.merge!({ page: { size: size, number: number } })
    get options[:action], params, headers
  end

  context 'for any collection' do
    before(:each) { get_with_pagination(options, size) }

    it 'returns the paginated results' do
      expect(data.size).to be <= size
    end

    it 'includes "record_count" in "meta"' do
      record_count = json['meta']['record_count']
      expect(record_count).to eq(options[:count])
    end

    it 'includes pagination links' do
      expect(links['first']).to be_present
      expect(links['last']).to be_present
    end
  end

  context 'when data is not empty' do
    context 'when in the beginning of the pagination' do
      before(:each) { get_with_pagination(options, size) }

      it 'includes the "next" node' do
        expect(links['next']).to be_present
      end

      it 'does not include the "previous" node' do
        expect(links['previous']).not_to be_present
      end
    end

    if options[:count].to_i > 2
      context 'when in middle of the pagination' do
        before(:each) { get_with_pagination(options, 1, 2) }

        it 'includes the "next" node' do
          expect(links['next']).to be_present
        end

        it 'includes the "previous" node' do
          expect(links['previous']).to be_present
        end
      end
    end
  end
end
