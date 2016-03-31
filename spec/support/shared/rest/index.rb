require 'spec_helper'

shared_examples_for 'JSON API #index action' do |options|
  let(:params) { options[:params] || {} }

  context 'when invalid' do
    it_behaves_like 'request with error', action: options[:action], record: options[:params]
  end

  context 'when valid' do
    after(:each) { expect(response).to have_http_status 200 }

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

      context 'page' do
        context 'default nodes' do
          page = { number: 1, size: 1 }
          subject(:response) { get options[:action], params.merge(page: page) }
          include_examples 'page', page.merge(count: options[:count])
          include_examples 'first page'
        end

        context 'in the middle of the pagination' do
          page = { number: 2, size: 1 }
          subject(:response) { get options[:action], params.merge(page: page) }
          include_examples 'middle page'
        end

        context 'beyond the last page' do
          page = { number: 9999, size: 1 }
          subject(:response) { get options[:action], params.merge(page: page) }
          include_examples 'beyond the last page'
        end
      end
    end
  end
end
