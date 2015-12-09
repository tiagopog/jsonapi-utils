require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  OPTIONS = {
    resource: :users,
    fields: UserResource.fields - [:posts],
    include: %i(posts)
  }

  before(:all) { create_list(:user, 3, :with_posts) }

  describe 'GET #index' do
    context 'when invalid' do
      it_behaves_like 'request with error', action: :index
    end

    context 'when valid' do
      options = OPTIONS.merge({
        action: :index,
        record: { id: 1 },
        count: 3
      })
      it_behaves_like 'JSON API request', options
    end
  end

  describe 'GET #show' do
    context 'when invalid' do
      options = { action: :show, record: { id: 9999 } }
      it_behaves_like 'request with error', options
    end
  end
end

