require 'rails_helper'

##
# Configs
##

# Resource
class PageCountTestResource < JSONAPI::Resource; end

# Controller
class PageCountTestController < BaseController
  def index
    jsonapi_render json: User.all, options: { resource: UserResource }
  end
end

# Routes
def TestApp.draw_page_count_test_routes
  JSONAPI.configuration.json_key_format = :underscored_key

  TestApp.routes.draw do
    controller :page_count_test do
      get :index
    end
  end
end

##
# Feature Tests
##

describe PageCountTestController, type: :controller do
  include_context 'JSON API headers'

  before(:all) do
    TestApp.draw_page_count_test_routes
    FactoryBot.create_list(:user, 3, :with_posts)
  end

  describe 'page count with a paged paginator' do
    it 'returns the correct count' do
      JSONAPI.configuration.default_paginator = :paged

      get :index, params: { page: { size: 2, number: 1 } }

      expect(json.dig('meta', 'page_count')).to eq(2)
    end
  end

  describe 'page count with an offset paginator' do
    it 'returns the correct count' do
      JSONAPI.configuration.default_paginator = :offset

      get :index, params: { page: { limit: 2, offset: 1 } }

      expect(json.dig('meta', 'page_count')).to eq(2)
    end
  end

  describe 'page count with a custom paginator' do
    it 'returns the correct count' do
      JSONAPI.configuration.default_paginator = :custom_offset

      get :index, params: { page: { limit: 2, offset: 1 } }

      expect(json.dig('meta', 'page_count')).to eq(2)
    end
  end

  describe 'using default limit param' do
    it 'returns the correct count' do
      JSONAPI.configuration.default_paginator = :offset

      get :index, params: { page: {  offset: 1 } }

      expect(json.dig('meta', 'page_count')).to eq(1)
    end
  end

  describe 'using a custom page_count key' do
    it 'returns the count with the correct key' do
      JSONAPI.configuration.default_paginator = :paged
      JSONAPI.configuration.top_level_meta_page_count_key = :total_pages

      get :index, params: { page: { limit: 2, offset: 1 } }

      expect(json.dig('meta', 'total_pages')).to eq(2)
    end
  end
end
