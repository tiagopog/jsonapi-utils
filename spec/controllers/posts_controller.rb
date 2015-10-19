require 'spec_helper'

RSpec.describe PostsController, type: :controller do
  subject(:post) { create(:post, :with_author) }
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }

  describe '#index' do
    before(:each) { expect(response).to have_http_status 200 }

    context 'when no query string is set' do
      # subject(:response) do
      #   get :index
      # end
      #
      # it 'returns a collection of posts' do
      # end
    end
  end
end
