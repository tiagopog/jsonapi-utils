shared_context 'JSON API headers' do
  let(:headers) do
    { 'Accept'       => 'application/vnd.api+json',
      'Content-Type' => 'application/vnd.api+json' }
  end

  before(:each) { request.headers.merge!(headers) }
end
