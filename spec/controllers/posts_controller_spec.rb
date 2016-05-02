require 'spec_helper'

describe PostsController, type: :controller do
  before(:all) { FactoryGirl.create_list(:post, 3) }

  let(:fields)        { (PostResource.fetchable_fields - %i(id author)).map(&:to_s) }
  let(:relationships) { %w(author) }
  let(:post)          { Post.first }

  describe '#show' do
    it 'renders a single post' do
      get :show, user_id: post.user_id, id: post.id
      expect(response).to have_http_status :ok
      expect(has_valid_id_and_type_members?('posts')).to be_truthy
      expect(has_relationship_members?(relationships)).to be_truthy
      expect(data['attributes']['title']).to eq("Title for Post #{post.id}")
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
