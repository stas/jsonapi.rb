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

      context 'returns customers and dasherized first name' do
        let(:params) do
          { upcase: :yes, fields: { unknown: nil } }
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response_json['data'].size).to eq(users.size)

          response_json['data'].each do |item|
            user = users.detect { |u| u.id == item['id'].to_i }
            expect(item).to have_attribute('first_name')
              .with_value(user.first_name.upcase)
          end
        end
      end

      context 'returns customers included and sparse fields' do
        let(:params) do
          {
            include: 'notes',
            fields:  { note: 'title,updated_at' }
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
            'id' => note.id.to_s,
            'type' => 'note',
            'relationships' => {},
            'attributes' => {
              'title' => note.title,
              'updated_at' => note.updated_at.as_json
            }
          )
        end
      end
    end
  end
end
