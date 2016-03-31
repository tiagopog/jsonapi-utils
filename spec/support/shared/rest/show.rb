require 'spec_helper'

shared_examples_for 'JSON API #show action' do |options|
  context 'when invalid' do
    context 'when not found' do
      it 'renders 404 response' do
        options[:params] ||= {}
        get :show, options[:params].merge(id: 9999)
        expect(response).to have_http_status :not_found
      end
    end
  end

  context 'when valid' do
    after(:each) { expect(response).to have_http_status :ok }

    let(:params) do
      options[:params] ||= {}
      options[:params].merge({ id: @collection.first.id })
    end

    context 'with no query string' do
      subject(:response) { get options[:action], params }
      it_behaves_like 'base top-level nodes', { resource: options[:resource] }
    end

    context 'with query string' do
      context 'fields' do
        subject(:response) do
          fields = { "#{options[:resource]}": Array(options[:fields]).join(',') }
          get options[:action], params.merge(fields: fields)
        end

        include_examples 'fields', options[:fields]
      end

      context 'include' do
        subject(:response) do
          includes = Array(options[:include]).map do |option|
            option.is_a?(Hash) ? option[:name] : option
          end.compact
          get options[:action], params.merge(include: includes.join(','))
        end
        include_examples 'include', options[:include]
      end
    end
  end
end
