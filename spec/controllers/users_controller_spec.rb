require 'spec_helper'

describe UsersController, type: :controller do
  before(:all) { FactoryGirl.create_list(:user, 3, :with_posts) }

  let(:fields) { (UserResource.fetchable_fields - %i(id posts)).map(&:to_s) }
  let(:relationships) { %w(posts) }

  include_examples 'JSON API invalid request', resource: :users

  context 'when response is invalid' do
    context 'when no "json" key is present' do
      it 'renders a 500 response', :aggregate_failures do
        get :no_json_key_failure
        expect(response).to have_http_status :internal_server_error
        expect(error['title']).to eq('Internal Server Error')
        expect(error['code']).to eq(500)
        expect(error['meta']['exception']).to eq('":json" key must be set to JSONAPI::Utils#jsonapi_render')
      end
    end
  end

  describe '#index' do
    it 'renders a collection of users', :aggregate_failures do
      get :index
      expect(response).to have_http_status :ok
      expect(has_valid_id_and_type_members?('users')).to be_truthy
      expect(has_fetchable_fields?(fields)).to be_truthy
      expect(has_relationship_members?(relationships)).to be_truthy
    end

    context 'with "include"' do
      it 'returns only the required relationships in the "included" member' do
        get :index, include: :posts
        expect(response).to have_http_status :ok
        expect(has_valid_id_and_type_members?('users')).to be_truthy
        expect(has_included_relationships?(%w(posts))).to be_truthy
      end
    end

    context 'with "fields"' do
      it 'returns only the required fields in the "attributes" member' do
        get :index, fields: { users: :first_name }
        expect(response).to have_http_status :ok
        expect(has_valid_id_and_type_members?('users')).to be_truthy
        expect(has_fetchable_fields?(%w(first_name))).to be_truthy
      end
    end

    context 'with "filter"' do
      let(:first_name) { User.first.first_name }

      it 'returns only results corresponding to the applied filter' do
        get :index, filter: { first_name: first_name }
        expect(response).to have_http_status :ok
        expect(has_valid_id_and_type_members?('users')).to be_truthy
        expect(record_count).to eq(1)
        expect(data[0]['attributes']['first_name']).to eq(first_name)
      end
    end

    context 'with "sort"' do
      context 'when asc' do
        it 'returns sorted results' do
          get :index, sort: :first_name

          first_name1 = data[0]['attributes']['first_name']
          first_name2 = data[1]['attributes']['first_name']

          expect(response).to have_http_status :ok
          expect(has_valid_id_and_type_members?('users')).to be_truthy
          expect(first_name1).to be <= first_name2
        end
      end

      context 'when desc' do
        it 'returns sorted results' do
          get :index, sort: '-first_name,-last_name'

          first_name1, last_name1 = data[0]['attributes'].values_at('first_name', 'last_name')
          first_name2, last_name2 = data[1]['attributes'].values_at('first_name', 'last_name')
          sorted = first_name1 > first_name2 || (first_name1 == first_name2 && last_name1 >= last_name2)

          expect(response).to have_http_status :ok
          expect(has_valid_id_and_type_members?('users')).to be_truthy
          expect(sorted).to be_truthy
        end
      end
    end
  end

  describe '#show' do
    context 'when resource was not found' do
      it 'renders a 400 response', :aggregate_failures do
        get :show, id: 999
        expect(response).to have_http_status :not_found
        expect(error['title']).to eq('Record not found')
        expect(error['code']).to eq(404)
      end
    end
  end
end
