require 'spec_helper'

RSpec.describe JSONAPI::Deserialization do
  let(:jsonapi_deserialize) { UsersController.new.method(:jsonapi_deserialize) }
  let(:document) do
    {
      data: {
        id: 1,
        type: 'note',
        attributes: {
          title: 'Title 1',
          date: '2015-12-20'
        },
        relationships: {
          author: {
            data: {
              type: 'user',
              id: 2
            }
          },
          second_author: {
            data: nil
          },
          notes: {
            data: [
              {
                type: 'note',
                id: 3
              },
              {
                type: 'note',
                id: 4
              }
            ]
          }
        }
      }
    }
  end

  describe '#jsonapi_deserialize' do
    it do
      expect(jsonapi_deserialize.call(document)).to eq(
        'id' => 1,
        'date' => '2015-12-20',
        'title' => 'Title 1',
        'author_id' => 2,
        'second_author_id' => nil,
        'note_ids' => [3, 4]
      )
    end

    context 'with `only`' do
      it do
        expect(jsonapi_deserialize.call(document, only: :notes)).to eq(
          'note_ids' => [3, 4]
        )
      end
    end

    context 'with `except`' do
      it do
        expect(
          jsonapi_deserialize.call(document, except: [:date, :title])
        ).to eq(
          'id' => 1,
          'author_id' => 2,
          'second_author_id' => nil,
          'note_ids' => [3, 4]
        )
      end
    end

    context 'with `polymorphic`' do
      it do
        expect(
          jsonapi_deserialize.call(
            document, only: :author, polymorphic: :author
          )
        ).to eq(
          'author_id' => 2,
          'author_type' => User.name
        )
      end
    end
  end
end
