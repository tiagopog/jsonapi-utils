require 'spec_helper'
require 'rspec/expectations'

describe PostsController, type: :controller do
  before(:all) { FactoryGirl.create_list(:post, 3) }

  let(:fields)        { (PostResource.fetchable_fields - %i(id author)).map(&:to_s) }
  let(:relationships) { %w(author) }
  let(:post)          { Post.first }

  describe '#index' do
    context 'with ActiveRecord::Relation' do
      it 'renders a collection of users' do
        get :index, user_id: post.user_id
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
        get :show, user_id: post.user_id, id: post.id
        expect(response).to have_http_status :ok
        expect(response).to have_primary_data('posts')
        expect(response).to have_data_attributes(fields)
        expect(response).to have_relationships(relationships)
        expect(data['attributes']['title']).to eq("Title for Post #{post.id}")
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
          get :show, user_id: post.user_id, id: 999
          expect(response).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include('999')
          expect(error['code']).to eq(404)
        end
      end

      context 'with uuid' do
        let(:uuid) { SecureRandom.uuid }

        it 'renders a 404 response' do
          get :show, user_id: post.user_id, id: uuid
          expect(response).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(uuid)
          expect(error['code']).to eq(404)
        end
      end

      context 'with slug' do
        let(:slug) { 'some-awesome-slug' }

        it 'renders a 404 response' do
          get :show, user_id: post.user_id, id: slug
          expect(response).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(slug)
          expect(error['code']).to eq(404)
        end
      end
    end
  end
end
