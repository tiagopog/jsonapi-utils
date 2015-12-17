shared_context 'request with error' do |options|
  shared_examples_for '400 response' do |options|
    it 'renders 400 response' do
      record = options[:record]
      params = record.nil? ? {} : { :"#{record.keys.first}" => 1 }
      params.merge!(options[:params])

      get options[:action], params

      expect(response).to have_http_status :bad_request
      expect(json['errors'][0]['title']).to eq(options[:expect][:title])
      expect(json['errors'][0]['code']).to eq(options[:expect][:code])
    end
  end

  context 'with an invalid query string parameter' do
    context 'when error is in "fields"' do
      context 'with an invalid resource name' do
        options.merge!(
          params: { fields: { foo: 'name' } },
          expect: { title: 'Invalid resource', code: 101 }
        )
        it_behaves_like '400 response', options
      end

      context 'with an invalid field' do
        options.merge!(
          params: { fields: { users: 'foo' } },
          expect: { title: 'Invalid field', code: 104 }
        )
        it_behaves_like '400 response', options
      end
    end

    context 'when error is at "include" param' do
      options.merge!(
        params: { include: 'foo' },
        expect: { title: 'Invalid field', code: 112 }
      )
      it_behaves_like '400 response', options
    end
  end

  if options[:action] == :index
    context 'when error is at "filter" param' do
      options.merge!(
        params: { filter: { foo: 'bar' } },
        expect: { title: 'Filter not allowed', code: 102 }
      )
      it_behaves_like '400 response', options
    end

    context 'when error is at "sort" param' do
      options.merge!(
        params: { sort: 'foo' },
        expect: { title: 'Invalid sort criteria', code: 114 }
      )
      it_behaves_like '400 response', options
    end

    context 'when error is at "page" param' do
      %i(number size).each do |field|
        context 'with invalid "number"' do
          options.merge!(
            params: { page: { "#{field}": 'foo' } },
            expect: { title: 'Invalid page value', code: 118 }
          )
          it_behaves_like '400 response', options
        end
      end
    end
  elsif !options[:record].nil?
    context 'with a not found record' do
      it 'renders 404 response' do
        get :show, options[:record]
        expect(response).to have_http_status :not_found
      end
    end
  end
end
