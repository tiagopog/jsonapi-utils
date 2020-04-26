# JSONAPI::Utils

[![Code Climate](https://codeclimate.com/github/tiagopog/jsonapi-utils/badges/gpa.svg)](https://codeclimate.com/github/tiagopog/jsonapi-utils)
[![Gem Version](https://badge.fury.io/rb/jsonapi-utils.svg)](https://badge.fury.io/rb/jsonapi-utils)
[![Build Status](https://travis-ci.org/tiagopog/jsonapi-utils.svg?branch=master)](https://travis-ci.org/tiagopog/jsonapi-utils)

Simple yet powerful way to get your Rails API compliant with [JSON API](http://jsonapi.org).

`JSONAPI::Utils` (JU) is built on top of [JSONAPI::Resources](https://github.com/cerebris/jsonapi-resources)
taking advantage of its resource-driven style and bringing a set of helpers to easily build modern JSON APIs 
with no or less learning curve.

After installing the gem and defining the resources/routes, it's as simple as calling a render helper:

```ruby
class UsersController < ActionController::Base
  include JSONAPI::Utils

  def index
    jsonapi_render json: User.all
  end
end
```

## Table of Contents

* [Installation](#installation)
* [Why JSONAPI::Utils?](#why-jsonapiutils)
* [Usage](#usage)
  * [Response](#response)
    * [Renders](#renders)
    * [Formatters](#formatters)
    * [Paginators](#paginators)
  * [Request](#request)
    * [Params helpers](#params-helpers)
* [Full example](#full-example)
  * [Models](#models)
  * [Resources](#resources)
  * [Routes & Controllers](#routes--controllers)
  * [Initializer](#initializer)
  * [Requests & Responses](#requests--responses)
    * [Index](#index)
    * [Index (options)](#index-options)
    * [Show](#show)
    * [Show (options)](#show-options)
    * [Relationships (identifier objects)](#relationships-identifier-objects)
    * [Nested resources](#nested-resources)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)

## Installation

Support:

* Ruby 1.9+ with Rails 4
* Ruby 2.4+ with Rails 5

For Rails 4 add this to your application's Gemfile:

```ruby
gem 'jsonapi-utils', '~> 0.4.9'
```

For Rails 5+:

```ruby
gem 'jsonapi-utils', '~> 0.7.3'
```

And then execute:

```shell
$ bundle
```

## Why JSONAPI::Utils?

One of the main motivations behind `JSONAPI::Utils` is to keep things explicit in controllers (no hidden actions :-) so that developers can easily understand and maintain their code. 

Unlike `JSONAPI::Resources` (JR), JU doesn't care about how you will operate your controller actions. The gem deals only with the request validation and response rendering (via JR's objects) and provides a set of helpers (renders, formatters etc) along the way. Thus developers can decide how to actually operate their actions: service objects, interactors etc.

## Usage

### Response

#### Renders

JU brings two main renders to the game, working pretty much the same way as Rails' `ActionController#render` method:

- jsonapi_render
- jsonapi_render_errors

**jsonapi_render**

It renders a JSON API-compliant response.

```ruby
# app/controllers/users_controller.rb
# GET /users
def index
  jsonapi_render json: User.all
end

# GET /users/:id
def show
  jsonapi_render json: User.find(params[:id])
end
```

Arguments:

  - `json`: object to be rendered as a JSON document: ActiveRecord object, Hash or Array<Hash>;
  - `status`: HTTP status code (Integer, String or Symbol). If ommited a status code will be automatically infered;
  - `options`:
    - `resource`: explicitly points the resource to be used in the serialization. By default, JU will select resources by inferencing from controller's name.
    - `count`: explicitly points the total count of records for the request in order to build a proper pagination. By default, JU will count the total number of records.
    - `model`: sets the model reference in cases when `json` is a Hash or a collection of Hashes.

Other examples:

```ruby
# Specify a particular HTTP status code
jsonapi_render json: new_user, status: :created

# Forcing a different resource
jsonapi_render json: User.all, options: { resource: V2::UserResource }

# Using a specific count
jsonapi_render json: User.some_weird_scope, options: { count: User.some_weird_scope_count }

# Hash rendering
jsonapi_render json: { data: { id: 1, first_name: 'Tiago' } }, options: { model: User }

# Collection of Hashes rendering
jsonapi_render json: { data: [{ id: 1, first_name: 'Tiago' }, { id: 2, first_name: 'Doug' }] }, options: { model: User }
```

**jsonapi_render_errors**

It renders a JSON API-compliant error response.

```ruby
# app/controllers/users_controller.rb
# POST /users
  def create
    user = User.new(user_params)
    if user.save
      jsonapi_render json: user, status: :created
    else
      jsonapi_render_errors json: user, status: :unprocessable_entity
    end
  end
```

Arguments:
  - Exception
  - `json`: object to be rendered as a JSON document: ActiveRecord, Exception, Array<Hash> or any object which implements the `errors` method;
  - `status`: HTTP status code (Integer, String or Symbol). If ommited a status code will be automatically infered from the error body.

Other examples:

```ruby
# Render errors from a custom exception:
jsonapi_render_errors Exceptions::MyCustomError.new(user)

# Render errors from an Array<Hash>:
errors = [{ id: 'validation', title: 'Something went wrong', code: '100' }]
jsonapi_render_errors json: errors, status: :unprocessable_entity
```

#### Formatters

In the backstage these are the guys which actually parse the ActiveRecord/Hash object to build a new Hash compliant with JSON API's specs. Formatters can be called anywhere in controllers being very useful if you need to do some work with the response's body before rendering the actual response.

> Note: the resulting Hash from those methods can not be passed as argument to `JSONAPI::Utils#jsonapi_render` or  `JSONAPI::Utils#jsonapi_render_error`, instead it needs to be rendered by the usual `ActionController#render`.

**jsonapi_format**

> Because of semantic reasons `JSONAPI::Utils#jsonapi_serialize` was renamed to `JSONAPI::Utils#jsonapi_format`.

```ruby
# app/controllers/users_controller.rb
def index
  body = jsonapi_format(User.all)
  render json: do_some_magic_with(body)
end
```

Arguments:
  - First: ActiveRecord object, Hash or Array<Hash>;
  - Last: Hash of options (same as `JSONAPI::Utils#jsonapi_render`).

#### Paginators

Pagination works out of the box on JU, you just need to decide which kind of paginator you'd like to use.

It's really easy to work with pagination on JU, actually it's just a matter of chosing the [paginator you wish](http://jsonapi-resources.com/v0.8/guide/configuration.html#Defaults) in your JR's config file:

```ruby
# config/initializers/jsonapi_resources.rb
JSONAPI.configure do |config|
  # :none, :offset, :paged, or a custom paginator name
  config.default_paginator = :paged

  # Output pagination links at top level
  config.top_level_links_include_pagination = true
  
  # Default sizes
  config.default_page_size = 70
  config.maximum_page_size = 100
end
```

As you may have noticed above, it's possible to use custom paginators. In order to create your own paginator your just need to define a class which inherits from `JSONAPI::Paginator` and implements the `#pagination_range` method which in turn must return the range to be applied over the resulting collection.

For example, if you would like to paginate over a collection of hashes, you may implement the `#pagination_range` method as below:

```ruby
class CustomPaginator < JSONAPI::Paginator
  def pagination_range(page_params)
    offset = page_params['offset']
    limit  = JSONAPI.configuration.default_page_size
    offset..offset + limit - 1 # resulting range
  end
```

And then it can be either set at the resource class level (e.g. UserResource.paginator :custom) or via config initializer:

```ruby
# config/initializers/jsonapi_resources.rb
JSONAPI.configure do |config|
  config.default_paginator = :custom
end
```

### Request

Before a controller action gets executed, `JSONAPI::Utils` will validate the request against JSON API's specs as well as evaluating the eventual query string params to check if they match the resource's definition. If something goes wrong during the validation process, JU will render an error response like this examples below:

```json
HTTP/1.1 400 Bad Request
Content-Type: application/vnd.api+json

{
  "errors": [
    {
      "title": "Invalid resource",
      "detail": "foo is not a valid resource.",
      "code": "101",
      "status": "400"
    },
    {
      "title": "Invalid resource",
      "detail": "foobar is not a valid resource.",
      "code": "101",
      "status": "400"
    },
    {
      "title": "Invalid field",
      "detail": "bar is not a valid relationship of users",
      "code": "112",
      "status": "400"
    }
  ]
}
```

#### Params helpers

JU brings helper methods as a shortcut to get values from permitted params based on the resource's configuration.

- `resource_params`:
  - Returns the permitted params present in the `attributes` JSON member;
    - Example: `{ name: 'Bilbo', gender: 'male', city: 'Shire' }`
  - Same of calling: `params.require(:data).require(:attributes).permit(:name, :gender, :city)`
- `relationship_params`:
  - Returns the relationship `id`s, distinguished by key, present in `relationships` JSON member;
    - Example: `{ author: 1, posts: [1, 2, 3] }`
  - Same as calling: `params.require(:relationships).require(:author).require(:data).permit(:id)`

## Full example

After installing the gem you simply need to:

1. Include the gem's module (`include JSONAPI::Utils`) in a controller (eg. `BaseController`);
2. Define the resources which will be exposed via REST API;
3. Define the application's routes;
4. Use JSONAPI Utils' helper methods (eg. renders, formatters, params helpers etc).

Ok, now it's time to start our complete example. So, let's say we have a Rails application for a super simple blog:

### Models

```ruby
# app/models/user.rb
class User < ActiveRecord::Base
  has_many :posts
  validates :first_name, :last_name, presence: true
end

# app/models/post.rb
class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  validates :title, :body, presence: true
end
```

### Resources

Here is where we define how our models are exposed as resources on the API:

```ruby
# app/resources/user_resource.rb
class UserResource < JSONAPI::Resource
  attributes :first_name, :last_name, :full_name, :birthday

  has_many :posts

  def full_name
    "#{@model.first_name} #{@model.last_name}"
  end
end

# app/resources/post_resource.rb
class PostResource < JSONAPI::Resource
  attributes :title, :body
  has_one :author
end
```

### Routes & Controllers

Let's define the routes using the `jsonapi_resources` method provided by JR:

```ruby
Rails.application.routes.draw do
  jsonapi_resources :users do
    jsonapi_resources :posts
  end
end
```

In controllers we just need to include the `JSONAPI::Utils` module.

> Note: some default rendering can be set like the below example where `jsonapi_render_not_found` is used when a record is not found in the database.

```ruby
# app/controllers/base_controller.rb
class BaseController < ActionController::Base
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found
end
```

With the helper methods inhirited from `JSONAPI::Utils` in our `BaseController`, now it's all about to write our actions like the following:

```ruby
# app/controllers/users_controller.rb
class UsersController < BaseController
  # GET /users
  def index
    users = User.all
    jsonapi_render json: users
  end

  # GET /users/:id
  def show
    user = User.find(params[:id])
    jsonapi_render json: user
  end

  # POST /users
  def create
    user = User.new(resource_params)
    if user.save
      jsonapi_render json: user, status: :created
    else
      jsonapi_render_errors json: user, status: :unprocessable_entity
    end
  end

  # PATCH /users/:id
  def update
    user = User.find(params[:id])
    if user.update(resource_params)
      jsonapi_render json: user
    else
      jsonapi_render_errors json: user, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    User.find(params[:id]).destroy
    head :no_content
  end
end
```

And:

```ruby
# app/controllers/posts_controller.rb
class PostsController < BaseController
  before_action :load_user, except: :create

  # GET /users/:user_id/posts
  def index
    jsonapi_render json: @user.posts, options: { count: 100 }
  end

  # GET /users/:user_id/posts/:id
  def show
    jsonapi_render json: @user.posts.find(params[:id])
  end

  # POST /posts
  def create
    post = Post.new(post_params)
    if post.save
      jsonapi_render json: post, status: :created
    else
      jsonapi_render_errors json: post, status: :unprocessable_entity
    end
  end

  private

  def post_params
    resource_params.merge(user_id: relationship_params[:author])
  end

  def load_user
    @user = User.find(params[:user_id])
  end
end
```

### Initializer

In order to enable a proper pagination, record count etc, an initializer could be defined such as:

```ruby
# config/initializers/jsonapi_resources.rb
JSONAPI.configure do |config|
  config.json_key_format = :underscored_key
  config.route_format = :dasherized_route

  config.allow_include = true
  config.allow_sort = true
  config.allow_filter = true

  config.raise_if_parameters_not_allowed = true

  config.default_paginator = :paged

  config.top_level_links_include_pagination = true

  config.default_page_size = 10
  config.maximum_page_size = 20

  config.top_level_meta_include_record_count = true
  config.top_level_meta_record_count_key = :record_count

  config.top_level_meta_include_page_count = true
  config.top_level_meta_page_count_key = :page_count

  config.use_text_errors = false

  config.exception_class_whitelist = []

  config.always_include_to_one_linkage_data = false
end
```

You may want a different configuration for your API. For more information check [this](https://github.com/cerebris/jsonapi-resources/#configuration).

### Requests & Responses

Here are examples of requests – based on those sample [controllers](#routes--controllers) – and their respective JSON responses.

* [Collection](#collection)
* [Collection (options)](#collection-options)
* [Single record](#single-record)
* [Record (options)](#single-record-options)
* [Relationships (identifier objects)](#relationships-identifier-objects)
* [Nested resources](#nested-resources)

#### Index

Request:

```
GET /users HTTP/1.1
Accept: application/vnd.api+json
```

Response:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "data": [
    {
      "id": "1",
      "type": "users",
      "links": {
        "self": "http://api.myblog.com/users/1"
      },
      "attributes": {
        "first_name": "Tiago",
        "last_name": "Guedes",
        "full_name": "Tiago Guedes",
        "birthday": null
      },
      "relationships": {
        "posts": {
          "links": {
            "self": "http://api.myblog.com/users/1/relationships/posts",
            "related": "http://api.myblog.com/users/1/posts"
          }
        }
      }
    },
    {
      "id": "2",
      "type": "users",
      "links": {
        "self": "http://api.myblog.com/users/2"
      },
      "attributes": {
        "first_name": "Douglas",
        "last_name": "André",
        "full_name": "Douglas André",
        "birthday": null
      },
      "relationships": {
        "posts": {
          "links": {
            "self": "http://api.myblog.com/users/2/relationships/posts",
            "related": "http://api.myblog.com/users/2/posts"
          }
        }
      }
    }
  ],
  "meta": {
    "record_count": 2
  },
  "links": {
    "first": "http://api.myblog.com/users?page%5Bnumber%5D=1&page%5Bsize%5D=10",
    "last": "http://api.myblog.com/users?page%5Bnumber%5D=1&page%5Bsize%5D=10"
  }
}
```

#### Index (options)

Request:

```
GET /users?include=posts&fields[users]=first_name,last_name,posts&fields[posts]=title&sort=first_name,last_name&page[number]=1&page[size]=1 HTTP/1.1
Accept: application/vnd.api+json
```

Response:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "data": [
    {
      "id": "2",
      "type": "users",
      "links": {
        "self": "http://api.myblog.com/users/2"
      },
      "attributes": {
        "first_name": "Douglas",
        "last_name": "André"
      },
      "relationships": {
        "posts": {
          "links": {
            "self": "http://api.myblog.com/users/2/relationships/posts",
            "related": "http://api.myblog.com/users/2/posts"
          },
          "data": []
        }
      }
    },
    {
      "id": "1",
      "type": "users",
      "links": {
        "self": "http://api.myblog.com/users/1"
      },
      "attributes": {
        "first_name": "Tiago",
        "last_name": "Guedes"
      },
      "relationships": {
        "posts": {
          "links": {
            "self": "http://api.myblog.com/users/1/relationships/posts",
            "related": "http://api.myblog.com/users/1/posts"
          },
          "data": [
            {
              "type": "posts",
              "id": "1"
            }
          ]
        }
      }
    }
  ],
  "included": [
    {
      "id": "1",
      "type": "posts",
      "links": {
        "self": "http://api.myblog.com/posts/1"
      },
      "attributes": {
        "title": "An awesome post"
      }
    }
  ],
  "meta": {
    "record_count": 2
  },
  "links": {
    "first": "http://api.myblog.com/users?fields%5Bposts%5D=title&fields%5Busers%5D=first_name%2Clast_name%2Cposts&include=posts&page%5Blimit%5D=2&page%5Boffset%5D=0&sort=first_name%2Clast_name",
    "last": "http://api.myblog.com/users?fields%5Bposts%5D=title&fields%5Busers%5D=first_name%2Clast_name%2Cposts&include=posts&page%5Blimit%5D=2&page%5Boffset%5D=0&sort=first_name%2Clast_name"
  }
}
```

#### Show

Request:

```
GET /users/1 HTTP/1.1
Accept: application/vnd.api+json
```

Response:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "data": {
    "id": "1",
    "type": "users",
    "links": {
      "self": "http://api.myblog.com/users/1"
    },
    "attributes": {
      "first_name": "Tiago",
      "last_name": "Guedes",
      "full_name": "Tiago Guedes",
      "birthday": null
    },
    "relationships": {
      "posts": {
        "links": {
          "self": "http://api.myblog.com/users/1/relationships/posts",
          "related": "http://api.myblog.com/users/1/posts"
        }
      }
    }
  }
}
```

#### Show (options)

Request:

```
GET /users/1?include=posts&fields[users]=full_name,posts&fields[posts]=title HTTP/1.1
Accept: application/vnd.api+json
```

Response:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "data": {
    "id": "1",
    "type": "users",
    "links": {
      "self": "http://api.myblog.com/users/1"
    },
    "attributes": {
      "full_name": "Tiago Guedes"
    },
    "relationships": {
      "posts": {
        "links": {
          "self": "http://api.myblog.com/users/1/relationships/posts",
          "related": "http://api.myblog.com/users/1/posts"
        },
        "data": [
          {
            "type": "posts",
            "id": "1"
          }
        ]
      }
    }
  },
  "included": [
    {
      "id": "1",
      "type": "posts",
      "links": {
        "self": "http://api.myblog.com/posts/1"
      },
      "attributes": {
        "title": "An awesome post"
      }
    }
  ]
}
```

#### Relationships (identifier objects)

Request:

```
GET /users/1/relationships/posts HTTP/1.1
Accept: application/vnd.api+json
```

Response:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "links": {
    "self": "http://api.myblog.com/users/1/relationships/posts",
    "related": "http://api.myblog.com/users/1/posts"
  },
  "data": [
    {
      "type": "posts",
      "id": "1"
    }
  ]
}
```

#### Nested resources

Request:

```
GET /users/1/posts HTTP/1.1
Accept: application/vnd.api+json
```

Response:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "data": [
    {
      "id": "1",
      "type": "posts",
      "links": {
        "self": "http://api.myblog.com/posts/1"
      },
      "attributes": {
        "title": "An awesome post",
        "body": "Lorem ipsum dolot sit amet"
      },
      "relationships": {
        "author": {
          "links": {
            "self": "http://api.myblog.com/posts/1/relationships/author",
            "related": "http://api.myblog.com/posts/1/author"
          }
        }
      }
    }
  ],
  "meta": {
    "record_count": 1
  },
  "links": {
    "first": "http://api.myblog.com/posts?page%5Bnumber%5D=1&page%5Bsize%5D=10",
    "last": "http://api.myblog.com/posts?page%5Bnumber%5D=1&page%5Bsize%5D=10"
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tiagopog/jsonapi-utils. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


