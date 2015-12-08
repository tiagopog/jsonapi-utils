shared_examples_for 'JSON API request' do |options|
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let(:params) { options.try(:params) || {}  }

  before(:each) { expect(response).to have_http_status 200 }

  def data
    json['data'].is_a?(Array) ? json['data'] : Array(json['data'])
  end

  it_behaves_like 'default request', options
end

shared_examples_for 'default request' do |options|
  context 'default request' do
    subject(:response) do
      get options[:action], params, headers
    end

    it_behaves_like 'base top-level nodes', options

    context 'query string' do
      context 'with "fields" param' do
        it 'returns only the listed fields' do
          field = options[:fields].delete_if { |e| e == :id }.sample
          fields = { "#{options[:resource]}": field }

          params.merge!({ fields: fields })
          get options[:action], params, headers

          expect(data[0]['attributes'].keys).to include_items(field.to_s)
        end
      end
    end
  end
end

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
    all_ok = data.all? { |e| e['type'] == 'users' }
    expect(all_ok).to be_truthy
  end
end

