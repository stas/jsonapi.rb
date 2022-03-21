# JSONAPI.rb :electric_plug:

[![Build Status](https://travis-ci.org/stas/jsonapi.rb.svg?branch=master)](https://travis-ci.org/stas/jsonapi.rb)

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

 * object serialization (powered by JSON:API Serializer, was `fast_jsonapi`)
 * [error handling](https://jsonapi.org/format/#errors) (parameters,
   validation, generic errors)
 * fetching of the data (support for
   [includes](https://jsonapi.org/format/#fetching-includes) and
   [sparse fields](https://jsonapi.org/format/#fetching-sparse-fieldsets))
 * [filtering](https://jsonapi.org/format/#fetching-filtering) and
   [sorting](https://jsonapi.org/format/#fetching-sorting) of the data
   (powered by Ransack, soft-dependency)
 * [pagination](https://jsonapi.org/format/#fetching-pagination) support

## But how?

Mainly by leveraging [JSON:API Serializer](https://github.com/jsonapi-serializer/jsonapi-serializer)
and [Ransack](https://github.com/activerecord-hackery/ransack).

Thanks to everyone who worked on these amazing projects!

## Sponsors

I'm grateful for the following companies for supporting this project!

<p align="center">
<a href="https://www.luneteyewear.com"><img src="https://user-images.githubusercontent.com/112147/136836142-2bfba96e-447f-4eb6-b137-2445aee81b37.png"/></a>
<a href="https://www.startuplandia.io"><img src="https://user-images.githubusercontent.com/112147/136836147-93f8ab17-2465-4477-a7ab-e38255483c66.png"/></a>
</p>


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

 * [Object serialization](#object-serialization)
 * [Collection meta](#collection-meta)
 * [Error handling](#error-handling)
 * [Includes and sparse fields](#includes-and-sparse-fields)
 * [Filtering and sorting](#filtering-and-sorting)
   * [Sorting using expressions](#sorting-using-expressions)
 * [Pagination](#pagination)
 * [Deserialization](#deserialization)

---

To enable the support for Rails, add this to an initializer:

```ruby
# config/initializers/jsonapi.rb
require 'jsonapi'

JSONAPI::Rails.install!
```

This will register the mime type and the `jsonapi` and `jsonapi_errors`
renderers.

### Object serialization

The `jsonapi` renderer will try to guess and resolve the serializer class based
on the object class, and if it is a collection, based on the first item in the
collection.

The naming scheme follows the `ModuleName::ClassNameSerializer` for an instance
of the `ModuleName::ClassName`.

Please follow the
[JSON:API Serializer guide](https://github.com/jsonapi-serializer/jsonapi-serializer#serializer-definition)
on how to define a serializer.

To provide a different naming scheme implement the `jsonapi_serializer_class`
method in your resource or application controller.

Here's an example:
```ruby
class CustomNamingController < ActionController::Base

  # ...

  private

  def jsonapi_serializer_class(resource, is_collection)
    JSONAPI::Rails.serializer_class(resource, is_collection)
  rescue NameError
    # your serializer class naming implementation
  end
end
```

To provide extra parameters to the serializer,
implement the `jsonapi_serializer_params` method.

Here's an example:
```ruby
class CustomSerializerParamsController < ActionController::Base

  # ...

  private

  def jsonapi_serializer_params
    {
      first_name_upcase: params[:upcase].present?
    }
  end
end
```

#### Collection meta

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

To use an exception notifier, overwrite the
`render_jsonapi_internal_server_error` method in your controller.

Here's an example:

```ruby
class MyController < ActionController::Base
  include JSONAPI::Errors

  def update
    record = Model.find(params[:id])

    if record.update(params.require(:data).require(:attributes).permit!)
      render jsonapi: record
    else
      render jsonapi_errors: record.errors, status: :unprocessable_entity
    end
  end

  private

  def render_jsonapi_internal_server_error(exception)
    # Call your exception notifier here. Example:
    # Raven.capture_exception(exception)
    super(exception)
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
  def jsonapi_include
    super & ['wanted_attribute']
  end
end
```

### Filtering and sorting

`JSONAPI::Filtering` uses the power of
[Ransack](https://github.com/activerecord-hackery/ransack#search-matchers)
to filter and sort over a collection of records.
The support is pretty extended and covers also relationships and composite
matchers.

Please add `ransack` to your `Gemfile` in order to benefit from this functionality!

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

#### Sorting using expressions

You can use basic aggregations like `min`, `max`, `avg`, `sum` and `count`
when sorting. This is an optional feature since SQL aggregations require
grouping. To enable expressions along with filters, use the option flags:

```ruby
options = { sort_with_expressions: true }
jsonapi_filter(User.all, allowed_fields, options) do |filtered|
  render jsonapi: result.group('id').to_a
end
```

This allows you to run queries like:

```bash
$ curl -X GET /api/resources?sort=-model_attr_sum
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

If you want to add the pagination information to your meta,
use the `jsonapi_pagination_meta` method:

```ruby
  def jsonapi_meta(resources)
    pagination = jsonapi_pagination_meta(resources)

    { pagination: pagination } if pagination.present?
  end

```

If you want to change the default number of items per page or define a custom logic to handle page size, use the
`jsonapi_page_size` method:

```ruby
  def jsonapi_page_size(pagination_params)
    per_page = pagination_params[:size].to_f.to_i
    per_page = 30 if per_page > 30 || per_page < 1
    per_page
  end
```
### Deserialization

`JSONAPI::Deserialization` provides a helper to transform a `JSONAPI` document
into a flat dictionary that can be used to update an `ActiveRecord::Base` model.

Here's an example using the `jsonapi_deserialize` helper:

```ruby
class MyController < ActionController::Base
  include JSONAPI::Deserialization

  def update
    model = MyModel.find(params[:id])

    if model.update(jsonapi_deserialize(params, only: [:attr1, :rel_one]))
      render jsonapi: model
    else
      render jsonapi_errors: model.errors, status: :unprocessable_entity
    end
  end
end
```

The `jsonapi_deserialize` helper accepts the following options:

 * `only`: returns exclusively attributes/relationship data in the provided list
 * `except`: returns exclusively attributes/relationship which are not in the list
 * `polymorphic`: will add and detect the `_type` attribute and class to the
   defined list of polymorphic relationships

This functionality requires support for _inflections_. If your project uses
`active_support` or `rails` you don't need to do anything. Alternatively, we will
try to load a lightweight alternative to `active_support/inflector` provided
by the `dry/inflector` gem, please make sure it's added if you want to benefit
from this feature.

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
