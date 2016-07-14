require 'spec_helper'
describe PostsController, type: :controller do
  include_context 'JSON API headers'

  before(:all) { FactoryGirl.create_list(:post, 3) }

  let(:fields)        { (PostResource.updatable_fields - %i(author)).map(&:to_s) }
  let(:relationships) { %w(author) }
  let(:first_post)    { Post.first }
  let(:user_id)       { first_post.user_id }

  let(:attributes) do
    { title: 'Lorem ipsum', body: 'Lorem ipsum dolor sit amet.' }
  end

  let(:author_params) do
    { data: { type: 'users', id: user_id } }
  end

  let(:post_params) do
    {
      data: {
        type: 'posts',
        attributes: attributes,
        relationships: { author: author_params }
      }
    }
  end

  describe '#index' do
    context 'with ActiveRecord::Relation' do
      it 'renders a collection of users' do
        get :index, user_id: user_id
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('posts')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
        expect(response).to have_meta_record_count(100)
      end
    end

    context 'with Hash' do
      it 'renders a collection of users' do
        get :index_with_hash
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('posts')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
      end
    end
  end

  describe '#show' do
    context 'with ActiveRecord' do
      it 'renders a single post' do
        get :show, user_id: user_id, id: first_post.id
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('posts')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
        expect(data['attributes']['title']).to eq("Title for Post #{first_post.id}")
      end
    end

    context 'with Hash' do
      it 'renders a single post' do
        get :show_with_hash, id: 1
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('posts')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
        expect(data['attributes']['title']).to eq('Lorem ipsum')
      end
    end

    context 'when resource was not found' do
      context 'with conventional id' do
        it 'renders a 404 response' do
          get :show, user_id: user_id, id: 999
          expect(response).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include('999')
          expect(error['code']).to eq('404')
        end
      end

      context 'with uuid' do
        let(:uuid) { SecureRandom.uuid }

        it 'renders a 404 response' do
          get :show, user_id: user_id, id: uuid
          expect(response).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(uuid)
          expect(error['code']).to eq('404')
        end
      end

      context 'with slug' do
        let(:slug) { 'some-awesome-slug' }

        it 'renders a 404 response' do
          get :show, user_id: user_id, id: slug
          expect(response).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(slug)
          expect(error['code']).to eq('404')
        end
      end
    end
  end

  describe '#create' do
    it 'creates a new post' do
      expect { post :create, post_params }.to change(Post, :count).by(1)
      expect(response).to have_http_status :created
      expect(response).to have_primary_data('posts')
      expect(response).to have_data_attributes(fields)
      expect(data['attributes']['title']).to eq(post_params[:data][:attributes][:title])
    end

    context 'when validation fails' do
      it 'render a 422 response' do
        post_params[:data][:attributes][:title] = nil

        expect { post :create, post_params }.to change(Post, :count).by(0)
        expect(response).to have_http_status :unprocessable_entity

        expect(errors[0]['id']).to eq('title')
        expect(errors[0]['title']).to eq('Title can\'t be blank')
        expect(errors[0]['code']).to eq('100')
      end
    end
  end
end
