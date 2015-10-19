shared_examples_for 'request with error' do |options|
  context 'with an invalid query string parameter' do
    it 'renders 400 response' do
      record = options[:record]
      params = record.nil? ? {} : { :"#{record[:key]}" => 1 }

      get options[:action], params.merge(fields: { foo: 'bar' }), headers

      expect(response).to have_http_status 400
    end
  end

  # TODO: add examples for include, filter and page

  unless options[:record].nil?
    context 'with a not found record' do
      it 'renders 404 response' do
        record = options[:record]
        get :index, { :"#{record[:key]}" => record[:value]}, headers
        expect(response).to have_http_status 404
      end
    end
  end
end
