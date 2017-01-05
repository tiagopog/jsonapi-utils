require 'spec_helper'

describe ProfileController, type: :controller do
  include_context 'JSON API headers'

  let(:fields)     { (ProfileResource.fields - %i(id)).map(&:to_s) }
  let(:resource)   { Profile }
  let(:attributes) { { location: 'Springfield, USA' } }

  let(:body) do
    {
      data: {
        type: 'profiles',
        id: '1234',
        attributes: attributes
      }
    }
  end

  describe '#show' do
    it 'renders from ActiveModel::Model logic' do
      get :show
      expect(response).to have_http_status :ok
      expect(response).to have_primary_data('profiles')
      expect(response).to have_data_attributes(fields)
    end
  end

  describe '#update' do
    it 'renders a 422 response' do
      patch :update, params: body
      expect(response).to have_http_status :unprocessable_entity
      expect(errors[0]['id']).to eq('location')
      expect(errors[0]['title']).to eq("Location can't be blank")
      expect(errors[0]['code']).to eq('100')
      expect(errors[0]['source']['pointer']).to eq('/data/attributes/location')
    end
  end
end
