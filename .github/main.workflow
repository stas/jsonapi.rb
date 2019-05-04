workflow "Tests" {
  on = "push"
  resolves = [
    "rspec-ruby2.3_rails4",
    "rspec-ruby2.6_rails4",
    "rspec-ruby2.6_rails5",
    "rspec-ruby2.6_rails6"
  ]
}

action "rspec-ruby2.3_rails4" {
  uses = "docker://ruby:2.3-alpine"
  env = {
    RAILS_VERSION = "~> 4"
    SQLITE3_VERSION = "~> 1.3.6"
  }
  args = [
    "sh", "-c",
    "apk add -U git build-base sqlite-dev && rm Gemfile.lock && bundle install && rake"
  ]
}

action "rspec-ruby2.6_rails4" {
  uses = "docker://ruby:2.6-alpine"
  needs = ["rspec-ruby2.3_rails4"]
  env = {
    RAILS_VERSION = "~> 4"
    SQLITE3_VERSION = "~> 1.3.6"
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

action "rspec-ruby2.6_rails6" {
  uses = "docker://ruby:2.6-alpine"
  needs = ["rspec-ruby2.6_rails5"]
  env = {
    RAILS_VERSION = "~> 6.0.0.rc1"
  }
  args = [
    "sh", "-c",
    "apk add -U git build-base sqlite-dev && rm Gemfile.lock && bundle install && rake"
  ]
}
