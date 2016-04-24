require 'spec_helper'

describe PostsController, type: :controller do
  before(:all) do
    @collection = create_list(:user, 3, :with_posts)
  end

  options = {
    params: { user_id: 1 },
    resource: :posts,
    fields: :title,
    include: [{ name: :author, type: :users }]
  }

  describe 'GET #index' do
    it_behaves_like 'JSON API #index action', options.merge(action: :index, count: 3)
  end

  describe 'GET #show' do
    it_behaves_like 'JSON API #show action', options.merge(action: :show)
  end
end
