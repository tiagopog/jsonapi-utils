shared_examples_for 'request with error' do |options|
  context 'with an invalid query string parameter' do
    context 'when error is in "fields"' do
      context 'with an invalid resource name' do
        it 'renders 400 response' do
          record = options[:record]
          params = record.nil? ? {} : { :"#{record[:key]}" => 1 }

          get options[:action], params.merge(fields: { foo: 'name' }), headers

          expect(response).to have_http_status 400
          expect(json['errors'][0]['title']).to eq('Invalid resource')
          expect(json['errors'][0]['code']).to eq(101)
        end
      end

      context 'with an invalid field' do
        it 'renders 400 response' do
          record = options[:record]
          params = record.nil? ? {} : { :"#{record[:key]}" => 1 }

          get options[:action], params.merge(fields: { users: 'foo' }), headers

          expect(response).to have_http_status 400
          expect(json['errors'][0]['title']).to eq('Invalid field')
          expect(json['errors'][0]['code']).to eq(104)
        end
      end
    end

    context 'when error is in "include"' do
      it 'renders 400 response' do
        record = options[:record]
        params = record.nil? ? {} : { :"#{record[:key]}" => 1 }

        get options[:action], params.merge(include: 'foo'), headers

        expect(response).to have_http_status 400
        expect(json['errors'][0]['title']).to eq('Invalid field')
        expect(json['errors'][0]['code']).to eq(112)
      end
    end

    context 'when error is in "sort"' do
      it 'renders 400 response' do
        record = options[:record]
        params = record.nil? ? {} : { :"#{record[:key]}" => 1 }

        get options[:action], params.merge(sort: 'foo'), headers

        expect(response).to have_http_status 400
        expect(json['errors'][0]['title']).to eq('Invalid sort criteria')
        expect(json['errors'][0]['code']).to eq(114)
      end
    end
  end

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

