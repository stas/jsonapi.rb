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
      let(:second_user) { create_note.user }
      let(:third_user) { create_user }
      let(:users) { [first_user, second_user, third_user] }
      let(:user) { users.last }

      context 'returns filtered users' do
        let(:params) do
          {
            filter: {
              last_name_or_first_name_cont_any: (
                "#{third_user.first_name[0..5]}%,#{self.class.name}"
              )
            }
          }
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response_json['data'].size).to eq(1)
          expect(response_json['data'][0]).to have_id(third_user.id.to_s)
        end
      end

      context 'returns sorted users by notes' do
        let(:params) do
          { sort: '-notes_created_at' }
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response_json['data'].size).to eq(3)
          expect(response_json['data'][0]).to have_id(second_user.id.to_s)
        end
      end
    end
  end
end
