shared_examples_for 'JSON API request' do |options|
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let(:params) { options.try(:params) || {}  }

  before(:each) { expect(response).to have_http_status 200 }

  it_behaves_like 'default request', options
end

shared_examples_for 'default request' do |options|
  context 'default request' do
    subject(:response) do
      get :index, params, headers
    end

    it 'has the "data" field' do
      expect(json['data']).to be_present
    end

    it 'has the "id" field' do
      all_ok = json['data'].all? { |e| e['id'].present? }
      expect(all_ok).to be_truthy
    end

    it 'has the "attributes" field' do
      all_ok = json['data'].all? { |e| e['attributes'].present? }
      expect(all_ok).to be_truthy
    end

    it "returns a collection of #{options[:resource]}" do
      all_ok = json['data'].all? { |e| e['type'] == 'users' }
      expect(all_ok).to be_truthy
    end
  end
end

