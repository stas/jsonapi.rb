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

It's quite a hassle to setup a Ruby (Rails) web application to use and follow
the JSON:API specifications.

The idea is simple, JSONAPI.rb offers a bunch of modules/mixins/glue,
add them to your controllers, call some methods, _profit_!

Main goals:
 * No _magic_ please
 * No DSLs please
 * Less code, less maintenance
 * Good docs and test coverage
 * Keep it up-to-date (or at least tell people this is for _grabs_)

The available features include:

 * object serialization powered by (Fast JSON API)
 * [error handling](https://jsonapi.org/format/#errors) (parameters,
   validation, generic errors)
 * fetching of the data (support for
   [includes](https://jsonapi.org/format/#fetching-includes) and
   [sparse fields](https://jsonapi.org/format/#fetching-sparse-fieldsets))
 * [filtering](https://jsonapi.org/format/#fetching-filtering) and
   [sorting](https://jsonapi.org/format/#fetching-sorting) of the data
   (powered by Ransack)
 * [pagination](https://jsonapi.org/format/#fetching-pagination) support

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

To enable the support for Rails, add this to an initializer:

```ruby
# config/initializers/jsonapi.rb
require 'jsonapi'

JSONAPI::Rails.install!
```

This will register the mime type and the `jsonapi` and `jsonapi_errors`
renderers.

### Object Serialization

The `jsonapi` renderer will try to guess and resolve the serializer class based
on the object class, and if it is a collection, based on the first item in the
collection.

The naming scheme follows the `ModuleName::ClassNameSerializer` for an instance
of the `ModuleName::ClassName`.

Please follow the
[Fast JSON API guide](https://github.com/Netflix/fast_jsonapi#serializer-definition)
on how to define a serializer.

#### Collection Meta

To provide meta information for a collection, provide the `jsonapi_meta`
controller method.

Here's an example:

```ruby
class MyController < ActionController::Base
  def index
    render jsonapi: Model.all
  end

  private

  def jsonapi_meta(resources)
    { total: resources.count } if resources.respond_to?(:count)
  end
end
```

### Error handling

`JSONAPI::Errors` provides a basic error handling. It will generate a valid
error response on exceptions from strong parameters, on generic errors or
when a record is not found.

To render the validation errors, just pass it to the error renderer.

Here's an example:

```ruby
class MyController < ActionController::Base
  include JSONAPI::Errors

  def update
    raise_error! if params[:id] == 'tada'

    record = Model.find(params[:id])

    if record.update(params.require(:data).require(:attributes).permit!)
      render jsonapi: record
    else
      render jsonapi_errors: record.errors, status: :unprocessable_entity
    end
  end
end
```

### _Includes_ and sparse fields

`JSONAPI::Fetching` provides support on inclusion of related resources and
serialization of only specific fields.

Here's an example:

```ruby
class MyController < ActionController::Base
  include JSONAPI::Fetching

  def index
    render jsonapi: Model.all
  end

  private

  # Overwrite/whitelist the includes
  def jsonapi_include(resources)
    super - [:unwanted_attribute]
  end
end
```

### Filtering and sorting

`JSONAPI::Filtering` uses the power of
[Ransack](https://github.com/activerecord-hackery/ransack#search-matchers)
to filter and sort over a collection of records.
The support is pretty extended and covers also relationships and composite
matchers.

Here's an example:

```ruby
class MyController < ActionController::Base
  include JSONAPI::Filtering

  def index
    allowed = [:model_attr, :relationship_attr]

    jsonapi_filter(Model.all, allowed) do |filtered|
      render jsonapi: filtered.result
    end
  end
end
```

This allows you to run queries like:

```bash
$ curl -X GET \
  /api/resources?filter[model_attr_or_relationship_attr_cont_any]=value,name\
  &sort=-model_attr,relationship_attr
```


### Pagination

`JSONAPI::Pagination` provides support for paginating model record sets as long
as enumerables.

Here's an example:

```ruby
class MyController < ActionController::Base
  include JSONAPI::Pagination

  def index
    jsonapi_paginate(Model.all) do |paginated|
      render jsonapi: paginated
    end
  end
end
```

This will generate the relevant pagination _links_.

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
