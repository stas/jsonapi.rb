require 'spec_helper'

RSpec.describe NotesController, type: :request do
  describe 'PUT /notes/:id' do
    let(:note) { create_note }
    let(:note_id) { note.id }
    let(:user) { note.user }
    let(:user_id) { user.id }
    let(:note_params) do
      {
        data: {
          attributes: { title: FFaker::Company.name },
          relationships: { user: { data: { id: user_id } } }
        }
      }
    end
    let(:params) { note_params }

    before do
      put(note_path(note_id), params: params.to_json, headers: jsonapi_headers)
    end

    it do
      expect(response).to have_http_status(:ok)
      expect(response_json['data']).to have_id(note.id.to_s)
      expect(response_json['meta']).to eq('single' => true)
    end

    context 'with a missing parameter in the payload' do
      let(:params) { {} }

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json['errors'].size).to eq(1)
        expect(response_json['errors'][0]['status']).to eq('422')
        expect(response_json['errors'][0]['title'])
          .to eq(Rack::Utils::HTTP_STATUS_CODES[422])
        expect(response_json['errors'][0]['source']).to eq('pointer' => '')
        expect(response_json['errors'][0]['detail']).to be_nil
      end
    end

    context 'with an invalid payload' do
      let(:params) do
        payload = note_params.dup
        payload[:data][:relationships][:user][:data][:id] = nil
        payload
      end

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json['errors'].size).to eq(1)
        expect(response_json['errors'][0]['status']).to eq('422')
        expect(response_json['errors'][0]['code']).to include('blank')
        expect(response_json['errors'][0]['title'])
          .to eq(Rack::Utils::HTTP_STATUS_CODES[422])
        expect(response_json['errors'][0]['source'])
          .to eq('pointer' => '/data/relationships/user')
        if Rails::VERSION::MAJOR >= 6 && Rails::VERSION::MINOR >= 1
          expect(response_json['errors'][0]['detail'])
            .to eq('User must exist')
        else
          expect(response_json['errors'][0]['detail'])
            .to eq('User can\'t be blank')
        end
      end

      context 'required by validations' do
        let(:params) do
          payload = note_params.dup
          payload[:data][:attributes][:title] = 'BAD_TITLE'
          payload[:data][:attributes][:quantity] = 100 + rand(10)
          payload
        end

        it do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_json['errors'].size).to eq(3)
          expect(response_json['errors'][0]['status']).to eq('422')
          expect(response_json['errors'][0]['code']).to include('invalid')
          expect(response_json['errors'][0]['title'])
            .to eq(Rack::Utils::HTTP_STATUS_CODES[422])
          expect(response_json['errors'][0]['source'])
              .to eq('pointer' => '/data/attributes/title')
          expect(response_json['errors'][0]['detail'])
            .to eq('Title is invalid')

          expect(response_json['errors'][1]['status']).to eq('422')

          if Rails::VERSION::MAJOR >= 5
            expect(response_json['errors'][1]['code']).to eq('invalid')
          else
            expect(response_json['errors'][1]['code']).to eq('has_typos')
          end

          expect(response_json['errors'][1]['title'])
            .to eq(Rack::Utils::HTTP_STATUS_CODES[422])
          expect(response_json['errors'][1]['source'])
            .to eq('pointer' => '/data/attributes/title')
          expect(response_json['errors'][1]['detail'])
            .to eq('Title has typos')

          expect(response_json['errors'][2]['status']).to eq('422')

          if Rails::VERSION::MAJOR >= 5
            expect(response_json['errors'][2]['code']).to eq('less_than')
          else
            expect(response_json['errors'][2]['code'])
              .to eq('must_be_less_than_100')
          end

          expect(response_json['errors'][2]['title'])
            .to eq(Rack::Utils::HTTP_STATUS_CODES[422])
          expect(response_json['errors'][2]['source'])
            .to eq('pointer' => '/data/attributes/quantity')
          expect(response_json['errors'][2]['detail'])
            .to eq('Quantity must be less than 100')
        end
      end

      context 'as a param attribute' do
        let(:params) do
          payload = note_params.dup
          payload[:data][:attributes].delete(:title)
          # To have any attribtues in the payload...
          payload[:data][:attributes][:created_at] = nil
          payload
        end

        it do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_json['errors'][0]['source'])
            .to eq('pointer' => '/data/attributes/title')
        end
      end
    end

    context 'with a bad note ID' do
      let(:user_id) { nil }
      let(:note_id) { rand(10) }

      it do
        expect(response).to have_http_status(:not_found)
        expect(response_json['errors'].size).to eq(1)
        expect(response_json['errors'][0]['status']).to eq('404')
        expect(response_json['errors'][0]['title'])
          .to eq(Rack::Utils::HTTP_STATUS_CODES[404])
        expect(response_json['errors'][0]['source']).to be_nil
        expect(response_json['errors'][0]['detail']).to be_nil
      end
    end

    context 'with an exception' do
      let(:user_id) { nil }
      let(:note_id) { 'tada' }

      it do
        expect(response).to have_http_status(:internal_server_error)
        expect(response_json['errors'].size).to eq(1)
        expect(response_json['errors'][0]['status']).to eq('500')
        expect(response_json['errors'][0]['title'])
          .to eq(Rack::Utils::HTTP_STATUS_CODES[500])
        expect(response_json['errors'][0]['source']).to be_nil
        expect(response_json['errors'][0]['detail']).to be_nil
      end
    end
  end
end
