require 'rails_helper'

describe UsersController, type: :controller do
  include_context 'JSON API headers'

  before(:all) do
    @user = FactoryBot.create_list(:user, 3, :with_posts).first
  end

  before(:each) do
    JSONAPI.configuration.json_key_format = :underscored_key
  end

  let(:user)          { @user }
  let(:relationships) { UserResource._relationships.keys.map(&:to_s) }
  let(:fields)        { UserResource.fields.reject { |e| e == :id }.map(&:to_s) - relationships }
  let(:attributes)    { { first_name: 'Yehuda', last_name: 'Katz' } }

  let(:user_params) do
    { data: { type: 'users', attributes: attributes } }
  end

  include_examples 'JSON API invalid request', resource: :users

  describe '#index' do
    it 'renders a collection of users' do
      get :index
      expect(response).to have_http_status :ok
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(response).to have_relationships(relationships - ['profile'])
    end

    context 'with "include"' do
      it 'returns only the required relationships in the "included" member' do
        get :index, params: { include: 'profile,posts' }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
        expect(response).to have_included_relationships
      end
    end

    context 'with "fields"' do
      it 'returns only the required fields in the "attributes" member' do
        get :index, params: { fields: { users: :first_name } }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_data_attributes(%w(first_name))
      end
    end

    context 'with "filter"' do
      let(:first_name) { user.first_name }
      let(:full_name)  { "#{user.first_name} #{user.last_name}" }

      it 'returns only results corresponding to the applied filter' do
        get :index, params: { filter: { first_name: first_name } }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_meta_record_count(1)
        expect(data.dig(0, 'attributes', 'first_name')).to eq(first_name)
      end

      it 'returns only results corresponding to the applied custom filter' do
        get :index, params: { filter: { full_name: full_name } }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_meta_record_count(1)
        expect(data.dig(0, 'attributes', 'full_name')).to eq(full_name)
      end

      context 'when using "dasherized_key"' do
        before do
          JSONAPI.configuration.json_key_format = :dasherized_key
        end

        it 'returns only results corresponding to the applied filter' do
          get :index, params: { filter: { 'first-name' => first_name } }
          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
          expect(data.dig(0, 'attributes', 'first-name')).to eq(first_name)
        end
      end

      context 'when using "camelized_key"' do
        before do
          JSONAPI.configuration.json_key_format = :camelized_key
        end

        it 'returns only results corresponding to the applied filter' do
          get :index, params: { filter: { 'firstName' => first_name } }
          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
          expect(data.dig(0, 'attributes', 'firstName')).to eq(first_name)
        end
      end
    end

    context 'with "page"' do
      context 'when using "paged" paginator' do
        before(:all) do
          JSONAPI.configuration.default_paginator = :paged
        end

        context 'at the first page' do
          it 'returns paginated results' do
            get :index, params: { page: { number: 1, size: 2 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(2)
            expect(response).to have_meta_record_count(3)

            expect(json.dig('meta', 'page_count')).to eq(2)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the middle' do
          it 'returns paginated results' do
            get :index, params: { page: { number: 2, size: 1 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(3)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the last page' do
          it 'returns paginated results' do
            get :index, params: { page: { number: 3, size: 1 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(3)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end


        context 'when filtering with pagination' do
          let(:count) { User.where(user.slice(:first_name, :last_name)).count }

          it 'returns paginated results according to the given filter' do
            get :index, params: { filter: { full_name: user.full_name }, page: { number: 1, size: 2 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(count)

            expect(json.dig('meta', 'page_count')).to eq(1)
            expect(data.dig(0, 'attributes', 'full_name')).to eq(user.full_name)
          end
        end

        context 'without "size"' do
          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            get :index, params: { page: { number: 1 } }
            expect(response).to have_http_status :ok
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
            expect(response).to have_meta_record_count(User.count)
            expect(json.dig('meta', 'page_count')).to eq(1)
          end
        end
      end

      context 'when using "offset" paginator' do
        before(:all) do
          JSONAPI.configuration.default_paginator = :offset
        end

        context 'at the first page' do
          it 'returns paginated results' do
            get :index, params: { page: { offset: 0, limit: 2 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(2)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(2)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the middle' do
          it 'returns paginated results' do
            get :index, params: { page: { offset: 1, limit: 1 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(3)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the last page' do
          it 'returns the paginated results' do
            get :index, params: { page: { offset: 2, limit: 1 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(3)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'without "limit"' do
          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            get :index, params: { page: { offset: 1 } }
            expect(response).to have_http_status :ok
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
            expect(response).to have_meta_record_count(User.count)
            expect(json.dig('meta', 'page_count')).to eq(1)
          end
        end
      end

      context 'when using custom global paginator' do
        before(:all) do
          JSONAPI.configuration.default_paginator = :custom_offset
        end

        context 'at the first page' do
          it 'returns paginated results' do
            get :index, params: { page: { offset: 0, limit: 2 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(2)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(2)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the middle' do
          it 'returns paginated results' do
            get :index, params: { page: { offset: 1, limit: 1 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(3)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the last page' do
          it 'returns the paginated results' do
            get :index, params: { page: { offset: 2, limit: 1 } }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(User.count)

            expect(json.dig('meta', 'page_count')).to eq(3)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'without "limit"' do
          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            get :index, params: { page: { offset: 1 } }
            expect(response).to have_http_status :ok
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
            expect(response).to have_meta_record_count(User.count)
            expect(json.dig('meta', 'page_count')).to eq(1)
          end
        end
      end
    end

    context 'with "sort"' do
      context 'when asc' do
        it 'returns sorted results' do
          get :index, params: { sort: :first_name }

          first_name1 = data.dig(0, 'attributes', 'first_name')
          first_name2 = data.dig(1, 'attributes', 'first_name')

          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
          expect(first_name1).to be <= first_name2
        end
      end

      context 'when desc' do
        it 'returns sorted results' do
          get :index, params: { sort: '-first_name,-last_name' }

          first_name_1, last_name_1 = data.dig(0, 'attributes').values_at('first_name', 'last_name')
          first_name_2, last_name_2 = data.dig(1, 'attributes').values_at('first_name', 'last_name')
          sorted = first_name_1 > first_name_2 || (first_name_1 == first_name_2 && last_name_1 >= last_name_2)

          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
          expect(sorted).to be_truthy
        end
      end

      context 'when using "dasherized_key"' do
        before do
          JSONAPI.configuration.json_key_format = :dasherized_key
        end

        it 'returns sorted results' do
          get :index, params: { sort: 'first-name' }

          first_name_1 = data.dig(0, 'attributes', 'first-name')
          first_name_2 = data.dig(1, 'attributes', 'first-name')

          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
          expect(first_name_1 < first_name_2).to be_truthy
        end
      end

      context 'when using "camelized_key"' do
        before do
          JSONAPI.configuration.json_key_format = :camelized_key
        end

        it 'returns sorted results' do
          get :index, params: { sort: 'firstName' }

          first_name_1 = data.dig(0, 'attributes', 'firstName')
          first_name_2 = data.dig(1, 'attributes', 'firstName')

          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
          expect(first_name_1 < first_name_2).to be_truthy
        end
      end
    end
  end

  describe '#show' do
    it 'renders a single user' do
      get :show, params: { id: user.id }
      expect(response).to have_http_status :ok
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(data.dig('attributes', 'first_name')).to eq("User##{user.id}")
    end

    context 'when resource was not found' do
      it 'renders a 404 response' do
        get :show, params: { id: 999 }
        expect(response).to have_http_status :not_found
        expect(error['title']).to eq('Record not found')
        expect(error['code']).to eq('404')
      end
    end
  end

  describe '#create' do
    it 'creates a new user' do
      expect { post :create, params: user_params }.to change(User, :count).by(1)
      expect(response).to have_http_status :created
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(data.dig('attributes', 'first_name')).to eq(user_params.dig(:data, :attributes, :first_name))
    end

    shared_examples_for '400 response' do |hash|
      before { user_params.dig(:data, :attributes).merge!(hash) }

      it 'renders a 400 response' do
        expect { post :create, params: user_params }.to change(User, :count).by(0)
        expect(response).to have_http_status :bad_request
        expect(error['title']).to eq('Param not allowed')
        expect(error['code']).to eq('105')
      end
    end

    context 'with a not permitted param' do
      it_behaves_like '400 response', foo: 'bar'
    end

    context 'with a param not present in resource\'s attribute list' do
      it_behaves_like '400 response', admin: true
    end

    context 'with validation error and no status code set' do
      before { user_params.dig(:data, :attributes).merge!(first_name: nil, last_name: nil) }

      it 'renders a 400 response by default' do
        expect { post :create, params: user_params }.to change(User, :count).by(0)
        expect(response).to have_http_status :bad_request

        expect(errors.dig(0, 'id')).to eq('first_name')
        expect(errors.dig(0, 'title')).to eq('can\'t be blank')
        expect(errors.dig(0, 'detail')).to eq('First name can\'t be blank')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source')).to be_nil

        expect(errors.dig(1, 'id')).to eq('last_name')
        expect(errors.dig(1, 'title')).to eq('can\'t be blank')
        expect(errors.dig(1, 'detail')).to eq('Last name can\'t be blank')
        expect(errors.dig(1, 'code')).to eq('100')
        expect(errors.dig(1, 'source')).to be_nil
      end
    end
  end

  describe '#update' do
    let(:post) { user.posts.first }

    let(:update_params) do
      user_params.tap do |params|
        params[:data][:id] = user.id
        params[:data][:attributes][:first_name] = 'Yukihiro'
        params[:data][:relationships] = relationship_params
        params.merge!(id: user.id)
      end
    end

    let(:relationship_params) do
      { posts: { data: [{ id: post.id, type: 'posts' }] } }
    end

    it 'update an existing user' do
      patch :update, params: update_params

      expect(response).to have_http_status :ok
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(data['attributes']['first_name']).to eq(user_params[:data][:attributes][:first_name])

      expect(user.reload.posts.count).to eq(1)
      expect(user.posts.first).to eq(post)
    end

    context 'when resource was not found' do
      before { update_params[:data][:id] = 999 }

      it 'renders a 404 response' do
        patch :update, params: update_params.merge(id: 999)
        expect(response).to have_http_status :not_found
        expect(error['title']).to eq('Record not found')
        expect(error['code']).to eq('404')
      end
    end

    context 'when validation fails' do
      before { update_params[:data][:attributes].merge!(first_name: nil, last_name: nil) }

      it 'render a 422 response' do
        patch :update, params: update_params
        expect(response).to have_http_status :unprocessable_entity
        expect(errors[0]['id']).to eq('my_custom_validation_error')
        expect(errors[0]['title']).to eq('My custom error message')
        expect(errors[0]['code']).to eq('125')
        expect(errors[0]['source']).to be_nil
      end
    end
  end

  describe 'use of JSONAPI::Resources\' default actions' do
    describe '#show_relationship' do
      it 'renders the user\'s profile' do
        get :show_relationship, params: { user_id: user.id, relationship: 'profile' }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('profiles')
      end
    end
  end
end
