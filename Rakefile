require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yaml'
require 'yardstick'

# TODO: Remove once merged...
#       https://github.com/toshimaru/rubocop-rails_config/pull/43
require 'rubocop'
module RuboCop
  Config::OBSOLETE_COPS = Config::OBSOLETE_COPS.dup
  Config::OBSOLETE_COPS.delete('Layout/FirstParameterIndentation')
end

desc('Documentation stats and measurements')
task('qa:docs') do
  yaml = YAML.load_file(File.expand_path('../.yardstick.yml', __FILE__))
  config = Yardstick::Config.coerce(yaml)
  measure = Yardstick.measure(config)
  measure.puts
  coverage = Yardstick.round_percentage(measure.coverage * 100)
  exit(1) if coverage < config.threshold
end

desc('Codestyle check and linter')
RuboCop::RakeTask.new('qa:code') do |task|
  task.fail_on_error = true
  task.patterns = [
    'lib/**/*.rb',
    'spec/**/*.rb'
  ]
end

desc('Run CI QA tasks')
task(qa: ['qa:docs', 'qa:code'])

RSpec::Core::RakeTask.new(spec: :qa)
task(default: :spec)
