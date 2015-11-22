shared_examples_for 'request with error' do |options|
  context 'with an invalid query string parameter' do
    context 'when error is in "fields"' do
      context 'with an invalid resource name' do
        it 'renders 400 response' do
          record = options[:record]
          params = record.nil? ? {} : { :"#{record[:key]}" => 1 }
          params.merge!(fields: { foo: 'name' })

          get options[:action], params, headers

          expect(response).to have_http_status 400
          expect(json['errors'][0]['title']).to eq('Invalid resource')
          expect(json['errors'][0]['code']).to eq(101)
        end
      end

      context 'with an invalid field' do
        it 'renders 400 response' do
          record = options[:record]
          params = record.nil? ? {} : { :"#{record[:key]}" => 1 }
          params.merge!(fields: { users: 'foo' })

          get options[:action], params, headers

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
        params.merge!(include: 'foo')

        get options[:action], params, headers

        expect(response).to have_http_status 400
        expect(json['errors'][0]['title']).to eq('Invalid field')
        expect(json['errors'][0]['code']).to eq(112)
      end
    end
  end

  if options[:action] == :index
    context 'when error is in "filter"' do
      it 'renders 400 response' do
        get options[:action], { filter: { foo: 'bar' } }, headers

        expect(response).to have_http_status 400
        expect(json['errors'][0]['title']).to eq('Filter not allowed')
        expect(json['errors'][0]['code']).to eq(102)
      end
    end

    context 'when error is in "sort"' do
      it 'renders 400 response' do
        get options[:action], { sort: 'foo' }, headers

        expect(response).to have_http_status 400
        expect(json['errors'][0]['title']).to eq('Invalid sort criteria')
        expect(json['errors'][0]['code']).to eq(114)
      end
    end
  elsif !options[:record].nil?
    context 'with a not found record' do
      it 'renders 404 response' do
        record = options[:record]
        get :show, { :"#{record[:key]}" => record[:value]}, headers
        expect(response).to have_http_status 404
      end
    end
  end
end

