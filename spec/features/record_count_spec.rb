require 'spec_helper'

##
# Configs
##

# Resource
class RecordCountTestResource < JSONAPI::Resource; end

# Controller
class RecordCountTestController < BaseController
  def explicit_count
    jsonapi_render json: User.all, options: { count: 42, resource: UserResource }
  end

  def array_count
    jsonapi_render json: User.all.to_a, options: { resource: UserResource }
  end

  def active_record_count
    jsonapi_render json: User.all, options: { resource: UserResource }
  end

  def active_record_count_with_eager_load
    users = User.all.includes(:posts)
    jsonapi_render json: users, options: { resource: UserResource }
  end

  def active_record_count_with_eager_load_and_where_clause
    users = User.all.includes(:posts).where(posts: { id: Post.first.id })
    jsonapi_render json: users, options: { resource: UserResource }
  end
end

# Routes
TestApp.routes.draw do
  controller :record_count_test do
    get :explicit_count
    get :array_count
    get :active_record_count
    get :active_record_count_with_eager_load
    get :active_record_count_with_eager_load_and_where_clause
  end
end

##
# Feature tests
##

describe RecordCountTestController, type: :controller do
  include_context 'JSON API headers'

  before(:all) do
    JSONAPI.configuration.json_key_format = :underscored_key
    FactoryGirl.create_list(:user, 3, :with_posts)
  end

  describe 'explicit count' do
    it 'returns the count based on the passed "options"' do
      get :explicit_count
      expect(response).to have_meta_record_count(42)
    end
  end

  describe 'array count' do
    it 'returns the count based on the array length' do
      get :array_count
      expect(response).to have_meta_record_count(User.count)
    end
  end

  describe 'active record count' do
    it 'returns the count based on the AR\'s query result' do
      get :active_record_count
      expect(response).to have_meta_record_count(User.count)
    end
  end

  describe 'active record count with eager load' do
    it 'returns the count based on the AR\'s query result' do
      get :active_record_count_with_eager_load
      expect(response).to have_meta_record_count(User.count)
    end
  end

  describe 'active record count with eager load and where clause' do
    it 'returns the count based on the AR\'s query result' do
      get :active_record_count_with_eager_load_and_where_clause
      count = User.joins(:posts).where(posts: { id: Post.first.id }).count
      expect(response).to have_meta_record_count(count)
    end
  end
end
