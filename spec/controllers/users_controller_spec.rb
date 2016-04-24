require 'spec_helper'

describe UsersController, type: :controller do
  context 'with invalid' do
    context 'with no "json" key present' do
      it 'renders a 500 response', :aggregate_failures do
        get :no_json_key_failure
        expect(response).to have_http_status :internal_server_error
        expect(errors['title']).to eq('Internal Server Error')
        expect(errors['code']).to eq(500)
        expect(errors['meta']['exception']).to eq('":json" key must be set to JSONAPI::Utils#jsonapi_render')
      end
    end

    context '"include"' do
      context 'when resource does not exist' do
        it 'renders a 400 response', :aggregate_failures do
          get :index, include: :foobar
          expect(response).to have_http_status :bad_request
          expect(errors['title']).to eq('Invalid field')
          expect(errors['code']).to eq(112)
        end
      end
    end

    context '"fields"' do
      context 'when resource does not exist' do
        it 'renders a 400 response', :aggregate_failures do
          get :index, fields: { foo: 'bar' }
          expect(response).to have_http_status :bad_request
          expect(errors['title']).to eq('Invalid resource')
          expect(errors['code']).to eq(101)
        end
      end

      context 'when field does not exist' do
        it 'renders a 400 response', :aggregate_failures do
          get :index, fields: { users: 'bar' }
          expect(response).to have_http_status :bad_request
          expect(errors['title']).to eq('Invalid field')
          expect(errors['code']).to eq(104)
        end
      end
    end

    context '"filter"' do
      context 'when filter is not allowed' do
        it 'renders a 400 response', :aggregate_failures do
          get :index, filter: { foo: 'bar' }
          expect(response).to have_http_status :bad_request
          expect(errors['title']).to eq('Filter not allowed')
          expect(errors['code']).to eq(102)
        end
      end
    end

    context '"page"' do
      context 'with "paged" paginator' do
        context 'with invalid number' do
          it 'renders a 400 response', :aggregate_failures do
            get :index, page: { number: 'foo' }
            expect(response).to have_http_status :bad_request
            expect(errors['title']).to eq('Invalid page value')
            expect(errors['code']).to eq(118)
          end
        end

        context 'with invalid size' do
          it 'renders a 400 response', :aggregate_failures do
            get :index, page: { size: 'foo' }
            expect(response).to have_http_status :bad_request
            expect(errors['title']).to eq('Invalid page value')
            expect(errors['code']).to eq(118)
          end
        end

        context 'with invalid page param' do
          it 'renders a 400 response', :aggregate_failures do
            get :index, page: { offset: 1 }
            expect(response).to have_http_status :bad_request
            expect(errors['title']).to eq('Page parameter not allowed')
            expect(errors['code']).to eq(105)
          end
        end
      end

      context 'with "offset" paginator' do
        before(:all) { UserResource.paginator :offset }

        context 'with invalid offset' do
          it 'renders a 400 response', :aggregate_failures do
            get :index, page: { offset: -1 }
            expect(response).to have_http_status :bad_request
            expect(errors['title']).to eq('Invalid page value')
            expect(errors['code']).to eq(118)
          end
        end

        context 'with invalid limit' do
          it 'renders a 400 response', :aggregate_failures do
            JSONAPI.configuration.default_paginator = :offset
            get :index, page: { limit: 'foo' }
            expect(response).to have_http_status :bad_request
            expect(errors['title']).to eq('Invalid page value')
            expect(errors['code']).to eq(118)
          end
        end

        context 'with invalid page param' do
          it 'renders a 400 response', :aggregate_failures do
            get :index, page: { size: 1 }
            expect(response).to have_http_status :bad_request
            expect(errors['title']).to eq('Page parameter not allowed')
            expect(errors['code']).to eq(105)
          end
        end
      end
    end

    context '"sort"' do
      context 'when sort criteria is invalid' do
        it 'renders a 400 response', :aggregate_failures do
          get :index, sort: 'foo'
          expect(response).to have_http_status :bad_request
          expect(errors['title']).to eq('Invalid sort criteria')
          expect(errors['code']).to eq(114)
        end
      end
    end
  end
end
