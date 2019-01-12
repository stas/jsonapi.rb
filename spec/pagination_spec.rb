require 'spec_helper'

RSpec.describe UsersController, type: :request do
  describe 'GET /users' do
    let!(:user) { }
    let(:params) do
      {
        page: { number: 'Nan' },
        sort: '-created_at'
      }
    end

    before do
      get(users_path, params: params, headers: jsonapi_headers)
    end

    it do
      expect(response_json['data'].size).to eq(0)
      expect(response_json['meta']).to eq('many' => true)
    end

    context 'with users' do
      let(:first_user) { create_user }
      let(:second_user) { create_user }
      let(:third_user) { create_user }
      let(:users) { [first_user, second_user, third_user] }
      let(:user) { users.last }

      context 'returns users with pagination links' do
        it do
          expect(response).to have_http_status(:ok)
          expect(response_json['data'].size).to eq(3)
          expect(response_json['data'][0]).to have_id(third_user.id.to_s)
          expect(response_json['data'][1]).to have_id(second_user.id.to_s)
          expect(response_json['data'][2]).to have_id(first_user.id.to_s)

          expect(response_json).to have_link('self')
          expect(response_json).not_to have_link(:prev)
          expect(response_json).not_to have_link(:next)
          expect(response_json).not_to have_link(:first)
          expect(response_json).not_to have_link(:last)

          expect(CGI.unescape(response_json['links']['self']))
            .to include(CGI.unescape(params.to_query))
        end

        context 'even when it is an array' do
          let(:params) { { sort: '-created_at', as_list: true } }

          it do
            expect(response).to have_http_status(:ok)
            expect(response_json['data'].size).to eq(3)
          end
        end

        context 'on page 2 out of 3' do
          let(:params) do
            {
              page: { number: 2, size: 1 },
              sort: '-created_at'
            }
          end

          it do
            expect(response).to have_http_status(:ok)
            expect(response_json['data'].size).to eq(1)
            expect(response_json['data'][0]).to have_id(second_user.id.to_s)

            expect(response_json).to have_link(:self)
            expect(response_json).to have_link(:prev)
            expect(response_json).to have_link(:first)
            expect(response_json).to have_link(:next)
            expect(response_json).to have_link(:last)

            expect(CGI.unescape(response_json['links']['self']))
              .to include(CGI.unescape(params.to_query))
            expect(CGI.unescape(response_json['links']['self']))
              .to include('page[number]=2')
            expect(CGI.unescape(response_json['links']['prev']))
              .to include('page[number]=1')
            expect(CGI.unescape(response_json['links']['first']))
              .to include('page[number]=1')
            expect(CGI.unescape(response_json['links']['next']))
              .to include('page[number]=3')
            expect(CGI.unescape(response_json['links']['last']))
              .to include('page[number]=3')
          end
        end

        context 'on page 3 out of 3' do
          let(:params) do
            {
              page: { number: 3, size: 1 }
            }
          end

          it do
            expect(response).to have_http_status(:ok)
            expect(response_json['data'].size).to eq(1)

            expect(response_json).to have_link(:self)
            expect(response_json).to have_link(:prev)
            expect(response_json).to have_link(:first)
            expect(response_json).not_to have_link(:next)
            expect(response_json).not_to have_link(:last)

            expect(CGI.unescape(response_json['links']['self']))
              .to include(CGI.unescape(params.to_query))
            expect(CGI.unescape(response_json['links']['prev']))
              .to include('page[number]=2')
            expect(CGI.unescape(response_json['links']['first']))
              .to include('page[number]=1')
          end
        end

        context 'on page 1 out of 3' do
          let(:params) do
            {
              page: { size: 1 },
              sort: '-created_at'
            }
          end

          it do
            expect(response).to have_http_status(:ok)
            expect(response_json['data'].size).to eq(1)
            expect(response_json['data'][0]).to have_id(third_user.id.to_s)

            expect(response_json).not_to have_link(:prev)
            expect(response_json).not_to have_link(:first)
            expect(response_json).to have_link(:next)
            expect(response_json).to have_link(:self)
            expect(response_json).to have_link(:last)

            expect(CGI.unescape(response_json['links']['self']))
              .to include(CGI.unescape(params.to_query))
            expect(CGI.unescape(response_json['links']['next']))
              .to include('page[number]=2')
            expect(CGI.unescape(response_json['links']['last']))
              .to include('page[number]=3')
          end
        end
      end
    end
  end
end
