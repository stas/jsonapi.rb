lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'jsonapi/version'

Gem::Specification.new do |spec|
  spec.name          = 'jsonapi.rb'
  spec.version       = JSONAPI::VERSION
  spec.authors       = ['Stas Suscov']
  spec.email         = ['stas@nerd.ro']

  spec.summary       = 'So you say you need JSON:API support in your API...'
  spec.description   = (
    'JSON:API serialization, error handling, filtering and pagination.'
  )
  spec.homepage      = 'https://github.com/stas/jsonapi.rb'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{lib,spec}/**/*', File::FNM_DOTMATCH)
  spec.files        += %w(LICENSE.txt README.md)
  spec.require_paths = ['lib']

  spec.add_dependency 'jsonapi-serializer'
  spec.add_dependency 'rack'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION']
  spec.add_development_dependency 'ransack'
  spec.add_development_dependency 'sqlite3', ENV['SQLITE3_VERSION']
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'jsonapi-rspec'
  spec.add_development_dependency 'yardstick'
  spec.add_development_dependency 'rubocop-rails_config'
  spec.add_development_dependency 'rubocop', ENV['RUBOCOP_VERSION']
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rubocop-performance'
end
