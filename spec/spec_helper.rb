require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_group 'Lib', 'lib'
  add_group 'Tests', 'spec'
end
SimpleCov.minimum_coverage 90

require 'dummy'
require 'ffaker'
require 'rspec/rails'
require 'jsonapi/rspec'

RSpec.configure do |config|
  config.include JSONAPI::RSpec

  config.use_transactional_fixtures = true
  config.mock_with :rspec
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module RSpecHelpers
  include Dummy.routes.url_helpers

  # Helper to return JSONAPI valid headers
  #
  # @return [Hash] the relevant content type &co
  def jsonapi_headers
    { 'Content-Type': Mime[:jsonapi].to_s }
  end

  # Parses and returns a deserialized JSON
  #
  # @return [Hash]
  def response_json
    JSON.parse(response.body)
  end

  # Creates an user
  #
  # @return [User]
  def create_user
    User.create!(
      first_name: FFaker::Name.first_name,
      last_name: FFaker::Name.last_name
    )
  end

  # Creates a note
  #
  # @return [Note]
  def create_note(user = nil)
    Note.create!(
      title: FFaker::Company.name,
      quantity: rand(10),
      user: (user || create_user)
    )
  end
end

RSpec.configure do |config|
  config.include RSpecHelpers, type: :request
  config.include RSpecHelpers, type: :controller
end
