workflow "Tests" {
  on = "push"
  resolves = [
    "rspec-ruby2.3_rails4",
    "rspec-ruby2.3_rails5",
    "rspec-ruby2.6_rails4",
    "rspec-ruby2.6_rails5"
  ]
}

action "rspec-ruby2.3_rails4" {
  uses = "docker://ruby:2.3-alpine"
  env = {
    RAILS_VERSION = "~> 4"
  }
  args = [
    "sh", "-c",
    "apk add -U git build-base sqlite-dev && rm Gemfile.lock && bundle install && rake"
  ]
}

action "rspec-ruby2.3_rails5" {
  uses = "docker://ruby:2.3-alpine"
  needs = ["rspec-ruby2.3_rails4"]
  env = {
    RAILS_VERSION = "~> 5"
  }
  args = [
    "sh", "-c",
    "apk add -U git build-base sqlite-dev && rm Gemfile.lock && bundle install && rake"
  ]
}

action "rspec-ruby2.6_rails4" {
  uses = "docker://ruby:2.6-alpine"
  needs = ["rspec-ruby2.3_rails5"]
  env = {
    RAILS_VERSION = "~> 4"
  }
  args = [
    "sh", "-c",
    "apk add -U git build-base sqlite-dev && rm Gemfile.lock && bundle install && rake"
  ]
}

action "rspec-ruby2.6_rails5" {
  uses = "docker://ruby:2.6-alpine"
  needs = ["rspec-ruby2.6_rails4"]
  env = {
    RAILS_VERSION = "~> 5"
  }
  args = [
    "sh", "-c",
    "apk add -U git build-base sqlite-dev && rm Gemfile.lock && bundle install && rake"
  ]
}
