require 'spec_helper'

RSpec.describe UsersController, type: :request do
  describe '#extract_attributes_and_predicate' do
    context 'mixed attributes (and/or)' do
      it 'extracts ANDs' do
        attributes, predicates = JSONAPI::Filtering
          .extract_attributes_and_predicates('attr1_and_attr2_eq')
        expect(attributes).to eq(['attr1', 'attr2'])
        expect(predicates.size).to eq(1)
        expect(predicates[0].name).to eq('eq')
      end
    end

    context 'mixed predicates' do
      it 'extracts in order' do
        attributes, predicates = JSONAPI::Filtering
          .extract_attributes_and_predicates('attr1_sum_eq')
        expect(attributes).to eq(['attr1'])
        expect(predicates.size).to eq(2)
        expect(predicates[0].name).to eq('sum')
        expect(predicates[1].name).to eq('eq')
      end
    end
  end

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

        context 'with a comma' do
          let(:params) do
            third_user.update(first_name: third_user.first_name + ',')

            {
              filter: { first_name_eq: third_user.first_name }
            }
          end

          it do
            expect(response).to have_http_status(:ok)
            expect(response_json['data'].size).to eq(1)
            expect(response_json['data'][0]).to have_id(third_user.id.to_s)
          end
        end
      end

      context 'returns sorted users by notes quantity sum' do
        let(:params) do
          { sort: '-notes_quantity_sum' }
        end

        it do
          expect(response).to have_http_status(:ok)
          expect(response_json['data'].size).to eq(3)
          expect(response_json['data'][0]).to have_id(second_user.id.to_s)
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
