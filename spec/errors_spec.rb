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
        expect(response_json['errors']).to contain_exactly(
          {
            'status' => '422',
            'source' => { 'pointer' => '' },
            'title' => 'Unprocessable Entity',
            'detail' => nil,
            'code' => nil
          }
        )
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
        expect(response_json['errors']).to contain_exactly(
          {
            'status' => '422',
            'source' => { 'pointer' => '/data/relationships/user' },
            'title' => 'Unprocessable Entity',
            'detail' => Rails.gem_version >= Gem::Version.new('6.1') ? 'User must exist' : 'User can\'t be blank',
            'code' => 'blank'
          }
        )
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
          expect(response_json['errors']).to contain_exactly(
            {
              'status' => '422',
              'source' => { 'pointer' => '/data/attributes/title' },
              'title' => 'Unprocessable Entity',
              'detail' => 'Title is invalid',
              'code' => 'invalid'
            },
            {
              'status' => '422',
              'source' => { 'pointer' => '/data/attributes/title' },
              'title' => 'Unprocessable Entity',
              'detail' => 'Title has typos',
              'code' => 'invalid'
            },
            {
              'status' => '422',
              'source' => { 'pointer' => '/data/attributes/quantity' },
              'title' => 'Unprocessable Entity',
              'detail' => 'Quantity must be less than 100',
              'code' => 'less_than'
            }
          )
        end
      end

      context "validations with non-interpolated messages" do
        let(:params) do
          payload = note_params.dup
          payload[:data][:attributes][:title] = 'SLURS ARE GREAT'
          payload
        end

        it do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_json['errors'].size).to eq(1)
          expect(response_json['errors']).to contain_exactly(
            {
              'status' => '422',
              'source' => { 'pointer' => '' },
              'title' => 'Unprocessable Entity',
              'detail' => 'Title has slurs',
              'code' => 'title_has_slurs'
            }
          )
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
          expect(response_json['errors']).to contain_exactly(
            {
              'status' => '422',
              'source' => { 'pointer' => '/data/attributes/title' },
              'title' => 'Unprocessable Entity',
              'detail' => nil,
              'code' => nil
            }
          )
        end
      end
    end

    context 'with a bad note ID' do
      let(:user_id) { nil }
      let(:note_id) { rand(10) }

      it do
        expect(response).to have_http_status(:not_found)
        expect(response_json['errors'].size).to eq(1)
        expect(response_json['errors']).to contain_exactly(
          {
            'status' => '404',
            'source' => nil,
            'title' => 'Not Found',
            'detail' => nil,
            'code' => nil
          }
        )
      end
    end

    context 'with an exception' do
      let(:user_id) { nil }
      let(:note_id) { 'tada' }

      it do
        expect(response).to have_http_status(:internal_server_error)
        expect(response_json['errors'].size).to eq(1)
        expect(response_json['errors']).to contain_exactly(
          {
            'status' => '500',
            'source' => nil,
            'title' => 'Internal Server Error',
            'detail' => nil,
            'code' => nil
          }
        )
      end
    end
  end
end
