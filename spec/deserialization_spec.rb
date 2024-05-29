require 'spec_helper'

RSpec.describe JSONAPI::Deserialization do
  let(:jsonapi_deserialize) { UsersController.new.method(:jsonapi_deserialize) }

  context 'for single resource' do
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

  context 'for many resources' do
    let(:document) do
      {
        data: [
          {
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
          },
          {
            id: 5,
            type: 'note',
            attributes: {
              title: 'Title 2',
              date: '2019-11-20'
            },
            relationships: {
              author: {
                data: {
                  type: 'user',
                  id: 6
                }
              },
              second_author: {
                data: nil
              },
              notes: {
                data: [
                  {
                    type: 'note',
                    id: 7
                  },
                  {
                    type: 'note',
                    id: 8
                  }
                ]
              }
            }
          },
          {
            id: 9,
            type: 'note',
            attributes: {
              title: 'Title 3',
              date: '2020-10-05'
            },
            relationships: {
              author: {
                data: {
                  type: 'user',
                  id: 10
                }
              },
              second_author: {
                data: nil
              },
              notes: {
                data: [
                  {
                    type: 'note',
                    id: 11
                  },
                  {
                    type: 'note',
                    id: 12
                  }
                ]
              }
            }
          }
        ]
      }
    end

    describe '#jsonapi_deserialize' do
      it do
        expect(jsonapi_deserialize.call(document)).to match_array(
          [
            {
              'id' => 1,
              'date' => '2015-12-20',
              'title' => 'Title 1',
              'author_id' => 2,
              'second_author_id' => nil,
              'note_ids' => [3, 4]
            },
            {
              'id' => 5,
              'date' => '2019-11-20',
              'title' => 'Title 2',
              'author_id' => 6,
              'second_author_id' => nil,
              'note_ids' => [7, 8]
            },
            {
              'id' => 9,
              'title' => 'Title 3',
              'date' => '2020-10-05',
              'author_id' => 10,
              'second_author_id' => nil,
              'note_ids' => [11, 12]
            }
          ]
        )
      end

      context 'with `only`' do
        it do
          expect(jsonapi_deserialize.call(document, only: :notes))
            .to match_array(
              [
                {
                  'note_ids' => [3, 4]
                },
                {
                  'note_ids' => [7, 8]
                },
                {
                  'note_ids' => [11, 12]
                }
              ]
            )
        end
      end

      context 'with `except`' do
        it do
          expect(jsonapi_deserialize.call(document, except: [:date, :title]))
            .to match_array(
              [
                {
                  'id' => 1,
                  'author_id' => 2,
                  'second_author_id' => nil,
                  'note_ids' => [3, 4]
                },
                {
                  'id' => 5,
                  'author_id' => 6,
                  'second_author_id' => nil,
                  'note_ids' => [7, 8]
                },
                {
                  'id' => 9,
                  'author_id' => 10,
                  'second_author_id' => nil,
                  'note_ids' => [11, 12]
                }
              ]
            )
        end
      end

      context 'with `polymorphic`' do
        it do
          expect(jsonapi_deserialize.call(
            document, only: :author, polymorphic: :author
          )).to match_array(
            [
              { 'author_id' => 2, 'author_type' => 'User' },
              { 'author_id' => 6, 'author_type' => 'User' },
              { 'author_id' => 10, 'author_type' => 'User' }
            ]
          )
        end
      end
    end
  end
end
