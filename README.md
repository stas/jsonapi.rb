# JSONAPI.rb :electric_plug:

So you say you need [JSON:API](https://jsonapi.org/) support in your API...

> - hey how did your hackathon go?
> - not too bad, we got Babel set up
> - yep…
> - yep.
>
>— [I Am Devloper](https://twitter.com/iamdevloper/status/787969734918668289)

Here are some _codes_ to help you build your next JSON:API compliable application
easier and faster.

## But why?

It's quite a hassle to setup a Ruby web application to use and follow the
JSON:API specifications.

The idea is simple, JSONAPI.rb offers a bunch of modules/mixins/glue,
add them to your controllers, call some methods, _profit_!

Main goals:
 * No _magic_ please
 * No DSLs please
 * Less code, less maintenance
 * Good docs and test coverage
 * Keep it up-to-date (or at least tell people this is for _grabs_)

## But how?

Mainly by leveraging [Fast JSON API](https://github.com/Netflix/fast_jsonapi)
and [Ransack](https://github.com/activerecord-hackery/ransack).

Thanks to everyone who worked on these amazing projects!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi.rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jsonapi.rb

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bundle` to install dependencies.

Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/stas/jsonapi.rb

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
