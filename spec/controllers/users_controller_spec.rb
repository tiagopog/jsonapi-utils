require 'spec_helper'

describe UsersController, type: :controller do
  include_context 'JSON API headers'

  before(:all) { FactoryGirl.create_list(:user, 3, :with_posts) }

  let(:fields)        { (UserResource.updatable_fields - %i(posts)).map(&:to_s) }
  let(:relationships) { %w(posts) }
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
      expect(response).to have_relationships(relationships)
    end

    context 'with "include"' do
      it 'returns only the required relationships in the "included" member' do
        get :index, include: :posts
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
        expect(response).to have_included_relationships
      end
    end

    context 'with "fields"' do
      it 'returns only the required fields in the "attributes" member' do
        get :index, fields: { users: :first_name }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_data_attributes(%w(first_name))
      end
    end

    context 'with "filter"' do
      let(:first_name) { User.first.first_name }

      it 'returns only results corresponding to the applied filter' do
        get :index, filter: { first_name: first_name }
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('users')
        expect(response).to have_meta_record_count(1)
        expect(data[0]['attributes']['first_name']).to eq(first_name)
      end
    end

    context 'with "page"' do
      context 'when using "paged" paginator' do
        before(:all) do
          JSONAPI.configuration.default_paginator = :paged
          UserResource.paginator :paged
        end

        context 'at the first page' do
          it 'returns the paginated results' do
            get :index, page: { number: 1, size: 2 }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(2)
            expect(response).to have_meta_record_count(3)

            expect(json['links']['first']).to be_present
            expect(json['links']['next']).to be_present
            expect(json['links']['last']).to be_present
          end
        end

        context 'at the middle' do
          it 'returns the paginated results' do
            get :index, page: { number: 2, size: 1 }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(3)

            expect(json['links']['first']).to be_present
            expect(json['links']['prev']).to be_present
            expect(json['links']['next']).to be_present
            expect(json['links']['last']).to be_present
          end
        end

        context 'at the last page' do
          it 'returns the paginated results' do
            get :index, page: { number: 3, size: 1 }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(3)

            expect(json['links']['first']).to be_present
            expect(json['links']['prev']).to be_present
            expect(json['links']['last']).to be_present
          end
        end

        context 'without "size"' do
          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            get :index, page: { number: 1 }
            expect(response).to have_http_status :ok
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
            expect(response).to have_meta_record_count(3)
          end
        end
      end

      context 'when using "offset" paginator' do
        before(:all) do
          JSONAPI.configuration.default_paginator = :offset
          UserResource.paginator :offset
        end

        context 'at the first page' do
          it 'returns the paginated results' do
            get :index, page: { offset: 0, limit: 2 }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(2)
            expect(response).to have_meta_record_count(3)

            expect(json['links']['first']).to be_present
            expect(json['links']['next']).to be_present
            expect(json['links']['last']).to be_present
          end
        end

        context 'at the middle' do
          it 'returns the paginated results' do
            get :index, page: { offset: 1, limit: 1 }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(3)

            expect(json['links']['first']).to be_present
            expect(json['links']['prev']).to be_present
            expect(json['links']['next']).to be_present
            expect(json['links']['last']).to be_present
          end
        end

        context 'at the last page' do
          it 'returns the paginated results' do
            get :index, page: { offset: 2, limit: 1 }

            expect(response).to have_http_status :ok
            expect(response).to have_primary_data('users')
            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(3)

            expect(json['links']['first']).to be_present
            expect(json['links']['prev']).to be_present
            expect(json['links']['last']).to be_present
          end
        end

        context 'without "limit"' do
          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            get :index, page: { offset: 1 }
            expect(response).to have_http_status :ok
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
            expect(response).to have_meta_record_count(3)
          end
        end
      end
    end

    context 'with "sort"' do
      context 'when asc' do
        it 'returns sorted results' do
          get :index, sort: :first_name

          first_name1 = data[0]['attributes']['first_name']
          first_name2 = data[1]['attributes']['first_name']

          expect(response).to have_http_status :ok
          expect(response).to have_primary_data('users')
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
          expect(response).to have_primary_data('users')
          expect(sorted).to be_truthy
        end
      end
    end
  end

  describe '#show' do
    let(:user) { User.first }

    it 'renders a single user' do
      get :show, id: user.id
      expect(response).to have_http_status :ok
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(data['attributes']['first_name']).to eq("User ##{user.id}")
    end

    context 'when resource was not found' do
      it 'renders a 404 response' do
        get :show, id: 999
        expect(response).to have_http_status :not_found
        expect(error['title']).to eq('Record not found')
        expect(error['code']).to eq('404')
      end
    end
  end

  describe '#create' do
    it 'creates a new user' do
      expect { post :create, user_params }.to change(User, :count).by(1)
      expect(response).to have_http_status :created
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(data['attributes']['first_name']).to eq(user_params[:data][:attributes][:first_name])
    end

    shared_examples_for '400 response' do |hash|
      it 'renders a 400 response' do
        user_params[:data][:attributes].merge!(hash)
        expect { post :create, user_params }.to change(User, :count).by(0)
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

    context 'when validation fails' do
      it 'render a 422 response' do
        user_params[:data][:attributes].merge!(first_name: nil, last_name: nil)

        expect { post :create, user_params }.to change(User, :count).by(0)
        expect(response).to have_http_status :unprocessable_entity

        expect(errors[0]['id']).to eq('first_name')
        expect(errors[0]['title']).to eq('First name can\'t be blank')
        expect(errors[0]['code']).to eq('100')
        expect(errors[0]['source']).to be_nil

        expect(errors[1]['id']).to eq('last_name')
        expect(errors[1]['title']).to eq('Last name can\'t be blank')
        expect(errors[1]['code']).to eq('100')
        expect(errors[1]['source']).to be_nil
      end
    end
  end

  describe '#update' do
    let(:user) { User.first }
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
      patch :update, update_params

      expect(response).to have_http_status :ok
      expect(response).to have_primary_data('users')
      expect(response).to have_data_attributes(fields)
      expect(data['attributes']['first_name']).to eq(user_params[:data][:attributes][:first_name])

      expect(user.reload.posts.count).to eq(1)
      expect(user.posts.first).to eq(post)
    end

    context 'when resource was not found' do
      it 'renders a 404 response' do
        update_params[:data][:id] = 999
        patch :update, update_params.merge(id: 999)
        expect(response).to have_http_status :not_found
        expect(error['title']).to eq('Record not found')
        expect(error['code']).to eq('404')
      end
    end

    context 'when validation fails' do
      it 'render a 422 response' do
        update_params[:data][:attributes].merge!(first_name: nil, last_name: nil)
        patch :update, update_params
        expect(response).to have_http_status :unprocessable_entity
        expect(errors[0]['id']).to eq('my_custom_validation_error')
        expect(errors[0]['title']).to eq('My custom error message')
        expect(errors[0]['code']).to eq('125')
        expect(errors[0]['source']).to be_nil
      end
    end
  end
end
