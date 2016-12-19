require 'spec_helper'

describe PostsController, type: :controller do
  include_context 'JSON API headers'

  before(:all) { FactoryGirl.create_list(:post, 3) }

  before(:each) do
    JSONAPI.configuration.json_key_format = :underscored_key
  end

  let(:fields)        { (PostResource.fields - %i(id author)).map(&:to_s) }
  let(:relationships) { %w(author) }
  let(:resource)      { Post.first }
  let(:parent_id)     { resource.user_id }

  let(:attributes) do
    { title: 'Lorem ipsum', body: 'Lorem ipsum dolor sit amet.' }
  end

  let(:author) do
    { data: { type: 'users', id: parent_id } }
  end

  let(:body) do
    {
      data: {
        type: 'posts',
        attributes: attributes,
        relationships: { author: author }
      }
    }
  end

  describe 'GET #index' do
    subject { get :index, params }

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
      subject { get :index_with_hash, params }

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

            expect(json.dig('links', 'first')).to be_present
            expect(json.dig('links', 'prev')).to be_present
            expect(json.dig('links', 'next')).not_to be_present
            expect(json.dig('links', 'last')).to be_present
          end
        end

        context 'without "limit"' do
          let(:offset) { 1 }
          let(:limit)  { nil }

          it 'returns the amount of results based on "JSONAPI.configuration.default_page_size"' do
            expect(subject).to have_http_status :ok
            expect(subject).to have_meta_record_count(4)
            expect(data.size).to be <= JSONAPI.configuration.default_page_size
          end
        end
      end
    end
  end

  describe 'GET #show' do
    context 'with ActiveRecord' do
      subject { get :show, id: resource.id  }

      it 'renders a single post' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)
        expect(data.dig('attributes', 'title')).to eq("Title for Post #{resource.id}")
      end
    end

    context 'with Hash' do
      subject { get :show_with_hash, id: resource.id }

      it 'renders a single post' do
        expect(subject).to have_http_status :ok
        expect(subject).to have_primary_data('posts')
        expect(subject).to have_data_attributes(fields)
        expect(subject).to have_relationships(relationships)
        expect(data.dig('attributes', 'title')).to eq('Lorem ipsum')
      end
    end

    context 'when resource was not found' do
      context 'with conventional id' do
        subject { get :show, id: 999 }

        it 'renders a 404 response' do
          expect(subject).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include('999')
          expect(error['code']).to eq('404')
        end
      end

      context 'with uuid' do
        subject { get :show, id: uuid }

        let(:uuid) { SecureRandom.uuid }

        it 'renders a 404 response' do
          expect(subject).to have_http_status :not_found
          expect(error['title']).to eq('Record not found')
          expect(error['detail']).to include(uuid)
          expect(error['code']).to eq('404')
        end
      end

      context 'with slug' do
        subject { get :show, id: slug }

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
    subject { post :create, params.merge(body) }

    let (:params) { { user_id: parent_id } }

    it 'creates a new post' do
      expect { subject }.to change(Post, :count).by(1)
      expect(response).to have_http_status :created
      expect(response).to have_primary_data('posts')
      expect(response).to have_data_attributes(fields)
      expect(data.dig('attributes', 'title')).to eq(body.dig(:data, :attributes, :title))
    end

    context 'when validation fails' do
      subject { post :create, params.merge(invalid_body) }

      let(:invalid_body) do
        body.tap { |b| b[:data][:attributes][:title] = nil }
      end

      it 'render a 422 response' do
        expect { subject }.to change(Post, :count).by(0)
        expect(response).to have_http_status :unprocessable_entity
        expect(errors[0]['id']).to eq('title')
        expect(errors[0]['title']).to eq('Title can\'t be blank')
        expect(errors[0]['code']).to eq('100')
      end
    end
  end

  describe 'PATCH #update' do
    context 'when using JR\'s default action' do
      subject { patch :update, params.merge(body) }

      let(:params) { { id: 1 } }
      let(:body)   { { data: { id: 1, type: 'posts', attributes: { title: 'Foo' } } } }

      it { expect(response).to have_http_status :ok }
    end
  end
end
