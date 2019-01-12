require 'spec_helper'

RSpec.describe UsersController, type: :request do
  describe 'GET /users' do
    let!(:user) { }
    let(:params) { }

    before do
      get(users_path, params: params, headers: jsonapi_headers)
    end

    context 'with users' do
      let(:first_user) { create_user }
      let(:second_user) { create_user }
      let(:third_user) { create_note.user }
      let(:users) { [first_user, second_user, third_user] }
      let(:user) { users.last }
      let(:note) { third_user.notes.first }

      context 'returns customers included and sparse fields' do
        let(:params) do
          {
            include: 'notes',
            fields:  { note: 'id,updated_at' }
          }
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response_json['data'].last)
            .to have_relationship(:notes)
            .with_data([
              { 'id' => note.id.to_s, 'type' => 'note' }
          ])
          expect(response_json['included']).to include(
            'id'   => note.id.to_s,
            'type' => 'note',
            'relationships' => {},
            'attributes' => {
              'updated_at' => note.updated_at.as_json
            }
          )
        end
      end
    end
  end
end
