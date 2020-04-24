require 'rails_helper'

describe PostsController, type: :controller do
  include_context 'JSON API headers'

  before(:all) do
    @post = FactoryBot.create_list(:post, 3).first
  end

  before(:each) do
    JSONAPI.configuration.json_key_format = :underscored_key
  end

  let(:relationships) { PostResource._relationships.keys.map(&:to_s) }
  let(:fields)        { PostResource.fields.reject { |e| e == :id }.map(&:to_s) - relationships }
  let(:blog_post)     { @post }
  let(:parent_id)     { blog_post.user_id }
  let(:category_id)   { blog_post.category_id }

  let(:attributes) do
    { title: 'Lorem ipsum', body: 'Lorem ipsum dolor sit amet.', content_type: 'article' }
  end

  let(:author) do
    { data: { type: 'users', id: parent_id } }
  end

  let(:category) do
    { data: { type: 'categories', id: category_id } }
  end

  let(:body) do
    {
      data: {
        type: 'posts',
        attributes: attributes,
        relationships: { author: author, category: category }
      }
    }
  end

  describe 'GET #index' do
    subject { get :index, params: params }

    let(:params) { { user_id: parent_id } }

    context 'with ActiveRecord::Relation' do
      it 'renders a collection of users' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)
        expect(subject).to have_meta_record_count(100)
      end
    end

    context 'with Hash' do
      subject { get :index_with_hash, params: params }

      it 'renders a collection of users' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)
      end

      context 'with sort' do
        let(:params) { { user_id: parent_id, sort: 'title,-body' } }

        it 'sorts Hashes by asc/desc order' do
          expect(subject).to have_http_status :ok

          sorted_data = data.sort do |a, b|
            comp = a.dig('attributes', 'title') <=> b.dig('attributes', 'title')
            comp == 0 ? b.dig('attributes', 'body') <=> a.dig('attributes', 'body') : comp
          end

          expect(data).to eq(sorted_data)
        end
      end

      context 'when using custom global paginator' do
        before(:all) do
          JSONAPI.configuration.default_paginator = :custom_offset
        end

        let(:params) { { user_id: parent_id, page: { offset: offset, limit: limit } } }
        let(:offset) { 0 }
        let(:limit)  { 2 }

        it 'returns paginated results' do
          expect(subject).to have_http_status :ok

          expect(data.size).to eq(2)
          expect(response).to have_meta_record_count(4)

          expect(json.dig('meta', 'page_count')).to be(2)
          expect(json.dig('links', 'first')).to be_present
          expect(json.dig('links', 'next')).to be_present
          expect(json.dig('links', 'last')).to be_present
        end

        context 'at the middle' do
          let(:offset) { 1 }
          let(:limit)  { 1 }

          it 'returns paginated results' do
            expect(subject).to have_http_status :ok

            expect(data.size).to eq(1)
            expect(response).to have_meta_record_count(4)

            expect(json.dig('meta', 'page_count')).to be(4)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'next')).to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'at the last page' do
          let(:offset) { 3 }
          let(:limit)  { 1 }

          it 'returns the paginated results' do
            expect(subject).to have_http_status :ok
            expect(subject).to have_meta_record_count(4)

            expect(data.size).to eq(1)

            expect(json.dig('meta', 'page_count')).to be(4)
            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'next')).not_to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'without "limit"' do
          let(:offset) { 1 }

          before { params[:page].delete(:limit) }

          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            expect(subject).to have_http_status :ok
            expect(subject).to have_meta_record_count(4)
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
            expect(json.dig('meta', 'page_count')).to be(1)
          end
        end
      end
    end
  end

  describe 'GET #show' do
    context 'with ActiveRecord' do
      subject { get :show, params: { id: blog_post.id  } }

      it 'renders a single post' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)
        expect(data.dig('attributes', 'title')).to eq("Title for Post #{blog_post.id}")
      end
    end

    context 'with Hash' do
      subject { get :show_with_hash, params: { id: blog_post.id } }

      it 'renders a single post' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(json).to_not have_key('relationships')
        expect(data.dig('attributes', 'title')).to eq('Lorem ipsum')
      end
    end

    context 'when resource was not found' do
      context 'with conventional id' do
        subject { get :show, params: { id: 999 } }

        it 'renders a 404 response' do
          expect(subject).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include('999')
          expect(error['code']).to eq('404')
        end
      end

      context 'with uuid' do
        subject { get :show, params: { id: uuid } }

        let(:uuid) { SecureRandom.uuid }

        it 'renders a 404 response' do
          expect(subject).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(uuid)
          expect(error['code']).to eq('404')
        end
      end

      context 'with slug' do
        subject { get :show, params: { id: slug } }

        let(:slug) { 'some-awesome-slug' }

        it 'renders a 404 response' do
          expect(subject).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(slug)
          expect(error['code']).to eq('404')
        end
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: params.merge(body) }

    let (:params) { { user_id: parent_id } }

    it 'creates a new post' do
      expect { subject }.to change(Post, :count).by(1)
      expect(subject).to have_http_status :created
      expect(subject).to have_primary_data('posts')
      expect(subject).to have_data_attributes(fields)
      expect(data.dig('attributes', 'title')).to eq(body.dig(:data, :attributes, :title))
    end

    context 'when validation fails on an attribute' do
      subject { post :create, params: params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |b| b[:data][:attributes][:title] = nil }
      end

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(response).to have_http_status :unprocessable_entity
        expect(errors.dig(0, 'id')).to eq('title#blank')
        expect(errors.dig(0, 'title')).to eq('can\'t be blank')
        expect(errors.dig(0, 'detail')).to eq('Title can\'t be blank')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to eq('/data/attributes/title')
      end
    end

    context 'when validation fails on a relationship' do
      subject { post :create, params: params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |b| b[:data][:relationships][:author] = nil }
      end

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(subject).to have_http_status :unprocessable_entity

        expect(errors.dig(0, 'id')).to eq('author#blank')
        expect(errors.dig(0, 'title')).to eq('can\'t be blank')
        expect(errors.dig(0, 'detail')).to eq('Author can\'t be blank')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to eq('/data/relationships/author')
      end
    end

    context 'when validation fails on a foreign key' do
      subject { post :create, params: params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |b| b[:data][:relationships][:category] = nil }
      end

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(subject).to have_http_status :unprocessable_entity

        expect(errors.dig(0, 'id')).to eq('category#blank')
        expect(errors.dig(0, 'title')).to eq('can\'t be blank')
        expect(errors.dig(0, 'detail')).to eq('Category can\'t be blank')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to eq('/data/relationships/category')
      end
    end

    context 'when validation fails on a private attribute' do
      subject { post :create, params: params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |body| body[:data][:attributes][:title] = 'Fail Hidden' }
      end

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(subject).to have_http_status :unprocessable_entity

        expect(errors.dig(0, 'id')).to eq('hidden_field#error_was_tripped')
        expect(errors.dig(0, 'title')).to eq('error was tripped')
        expect(errors.dig(0, 'detail')).to eq('Hidden field error was tripped')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to be_nil
      end
    end

    context 'when validation fails with a formatted attribute key' do
      subject { post :create, params: params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |b| b[:data][:attributes][:title] = 'Fail Hidden' }
      end

      let!(:key_format_was) { JSONAPI.configuration.json_key_format }

      before { JSONAPI.configure { |config| config.json_key_format = :dasherized_key } }
      after  { JSONAPI.configure { |config| config.json_key_format = key_format_was } }

      let(:attributes) do
        { title: 'Lorem ipsum', body: 'Lorem ipsum dolor sit amet.' }
      end

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(subject).to have_http_status :unprocessable_entity

        expect(errors.dig(0, 'id')).to eq('content-type#blank')
        expect(errors.dig(0, 'title')).to eq('can\'t be blank')
        expect(errors.dig(0, 'detail')).to eq('Content type can\'t be blank')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to eq('/data/attributes/content-type')
      end
    end

    context 'when validation fails with a locale other than :en' do
      subject { post :create, params: params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |b| b[:data][:attributes][:title] = nil }
      end

      before { I18n.locale = :ru }
      after  { I18n.locale = :en }

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(response).to have_http_status :unprocessable_entity
        expect(errors.dig(0, 'id')).to eq('title#blank')
        expect(errors.dig(0, 'title')).to eq('не может быть пустым')
        expect(errors.dig(0, 'detail')).to eq('Заголовок не может быть пустым')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to eq('/data/attributes/title')
      end
    end
  end

  describe 'GET #related_resources' do
    shared_context 'related_resources request' do |use_resource:, explicit_relationship:|
      subject { get :get_related_resources, params: params }
      let (:params) { {
        source: "users",
        user_id: parent_id,
        relationship: "posts",
        use_resource: use_resource,
        explicit_relationship: explicit_relationship
      } }
    end

    context 'using model as source' do
      include_context 'related_resources request', use_resource: false, explicit_relationship: false

      it 'loads all posts of a user' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)

        # it should use nested url
        expect(json.dig('links', 'first')).to include("/users/#{parent_id}/posts")
        expect(json.dig('links', 'last')).to include("/users/#{parent_id}/posts")
      end
    end

    context 'using model as source and relationship from options' do
      include_context 'related_resources request', use_resource: false, explicit_relationship: true

      it 'loads all posts of a user' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)

        # it should use nested url
        expect(json.dig('links', 'first')).to include("/users/#{parent_id}/posts")
        expect(json.dig('links', 'last')).to include("/users/#{parent_id}/posts")
      end
    end


    context 'using resource as source' do
      include_context 'related_resources request', use_resource: true, explicit_relationship: false

      it 'loads all posts of a user' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)

        # it should use nested url
        expect(json.dig('links', 'first')).to include("/users/#{parent_id}/posts")
        expect(json.dig('links', 'last')).to include("/users/#{parent_id}/posts")
      end
    end

    context 'using resource as source and relationship from options' do
      include_context 'related_resources request', use_resource: true, explicit_relationship: true

      it 'loads all posts of a user' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)

        # it should use nested url
        expect(json.dig('links', 'first')).to include("/users/#{parent_id}/posts")
        expect(json.dig('links', 'last')).to include("/users/#{parent_id}/posts")
      end
    end
  end

  describe 'PATCH #update' do
    shared_context 'update request' do |action:|
      subject { patch action, params: params.merge(body) }

      let(:params) { { id: 1 } }
      let(:body)   { { data: { id: 1, type: 'posts', attributes: { title: 'Foo' } } } }
    end

    context 'when using JR\'s default action' do
      include_context 'update request', action: :update
      it { expect(response).to have_http_status :ok }
    end

    context 'when validation fails on base' do
      include_context 'update request', action: :update_with_error_on_base

      it 'renders a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(response).to have_http_status :unprocessable_entity

        expect(errors.dig(0, 'id')).to eq('base#this_is_an_error_on_the_base')
        expect(errors.dig(0, 'title')).to eq('This is an error on the base')
        expect(errors.dig(0, 'code')).to eq('100')
        expect(errors.dig(0, 'source', 'pointer')).to eq('/data')
      end
    end
  end
end
