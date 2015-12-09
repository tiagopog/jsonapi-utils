require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  OPTIONS = {
    resource: :users,
    fields: UserResource.fields - [:id, :posts],
    include: %i(posts)
  }

  before(:all) { create_list(:user, 3, :with_posts) }

  describe 'GET #index' do
    context 'when invalid' do
      it_behaves_like 'JSON for collections with error'
    end

    context 'when valid' do
      it_behaves_like 'JSON for collections', OPTIONS
    end
  end

  describe 'GET #show' do
    context 'when valid' do
      it_behaves_like 'JSON for a single record', OPTIONS
    end

    context 'when invalid' do
      it_behaves_like 'JSON for a single record with error'
    end
  end
end

