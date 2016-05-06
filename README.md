# JSONAPI::Utils

[![Code Climate](https://codeclimate.com/github/b2beauty/jsonapi-utils/badges/gpa.svg)](https://codeclimate.com/github/b2beauty/jsonapi-utils)
[![Gem Version](https://badge.fury.io/rb/jsonapi-utils.svg)](https://badge.fury.io/rb/jsonapi-utils)
[![Build Status](https://travis-ci.org/b2beauty/jsonapi-utils.svg?branch=master)](https://travis-ci.org/b2beauty/jsonapi-utils)

Simple yet powerful way to have your Rails API compliant with [JSON API](http://jsonapi.org).

JSONAPI::Utils (JU) was built on top of [JSONAPI::Resources](https://github.com/cerebris/jsonapi-resources) taking advantage of its resource-driven style and bringing a Rails way to build modern APIs with no or less learning curve.

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'jsonapi-utils', '~> 0.4.3'
```

And then execute:

```shell
$ bundle
```

## Macros

### jsonapi_render

Validates the request and renders ActiveRecord/Hash objects into JSON API-compliant responses.

Arguments:

  - `json`: ActiveRecord or Hash object to be rendered as JSON document;
  - `status`: HTTP status code (Integer or Symbol). If ommited a status code will be automatically infered;
  - `options`:
    - `resource`: explicitly points the resource to be used in the serialization. By default, JU will select resources by inferencing from controller's name.
    - `count`: explicitly points the total count of records for the request in order to build a proper pagination. By default, JU will count the total number of records.
    - `model`: sets the model reference in cases when `json` is a Hash or a collection of Hashes.

```ruby
# Single resource rendering
jsonapi_render json: User.find(params[:id])

# Collection rendering
jsonapi_render json: User.all

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

### jsonapi_serialize

In the backstage that's the method that actually parsers ActiveRecord/Hash objects and builds a new Hash compliant with JSON API. It can be called anywhere in controllers, concerns etc.

```ruby
collection = jsonapi_serialize(User.all)
render json: do_some_magic_with(collection)
```

Arguments:
  - It receives a second optional argument with the same options for `jsonapi_render`.

## Usage

Let's say we have a Rails app for a super simple blog.

### Models

```ruby
# app/models/user.rb
class User < ActiveRecord::Base
  has_many :posts
  validates :first_name, :last_name, presence: true
end

# app/models/user.rb
class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  validates :title, :body, presence: true
end
```

### Resources

Here is where we define how the serialization will behave:

```ruby
# app/resources/user_resource.rb
class UserResource < JSONAPI::Resource
  attributes :first_name, :last_name, :full_name, :birthday
  attribute :full_name

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

Let's define our routes using the `jsonapi_resources` and `jsonapi_links` macros provied by the `jsonapi-resources` gem:

```ruby
Rails.application.routes.draw do
  jsonapi_resources :users do
    jsonapi_resources :posts
    jsonapi_links :posts
  end
end
```

And a base controller to include the features from `jsonapi-resources` and `jsonapi-utils`:

```ruby
# app/controllers/base_controller.rb
class BaseController < JSONAPI::ResourceController
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found
end
```

For this example, let's get focused only on read actions. After including `JSONAPI::Utils` we can use the `jsonapi_render` method
in order to generate responses which follow the JSON API's standards.

```ruby
# app/controllers/users_controller.rb
class UsersController < BaseController
  before_action :load_user, only: [:show]

  # GET /users
  def index
    jsonapi_render json: User.all
  end

  # GET /users/:id
  def show
    jsonapi_render json: @user
  end

  private

  def load_user
    @user = User.find(params[:id])
  end
end
```

And:

```ruby
# app/controllers/posts_controller.rb
class PostsController < BaseController
  before_action :load_user, only: [:index, :show]
  before_action :load_post, only: [:show]

  # GET /users/:user_id/posts
  def index
    posts = @user.posts.enabled
    jsonapi_render json: posts, options: { count: posts.count }
  end

  # GET /users/:user_id/posts/:id
  def show
    jsonapi_render json: @post
  end

  private

  def load_user
    @user = User.find(params[:user_id])
  end

  def load_post
    @post = @user.posts.find(params[:id])
  end
end
```

### Errors

#### Not found

As you might have seen in BaseController this line will handle all errors related to not found resources:

```ruby
rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found
```

The `jsonapi_render_not_found` method will produce the following error payload:

```json
HTTP/1.1 404 Not found
Content-Type: application/vnd.api+json

{
  "errors": [
    {
      "title": "Record not found",
      "detail": "The record identified by 3 could not be found.",
      "id": null,
      "href": null,
      "code": 404,
      "source": null,
      "links": null,
      "status": "not_found"
    }
  ]
}
```

In case you prefer rendering not found resources with null data and `200 OK` status code, you can use `jsonapi_render_not_found_with_null` to produce:

```json
HTTP/1.1 200 OK
Content-Type: application/vnd.api+json

{
  "data": null
}
```

If you need to create custom error message, check [this](https://github.com/cerebris/jsonapi-resources#error-codes).

### Initializer

In order to enable a proper pagination, record count etc, let's define an initializer such as:

```ruby
# config/initializers/jsonapi_resources.rb
JSONAPI.configure do |config|
  config.json_key_format = :underscored_key
  config.route_format = :dasherized_route

  config.operations_processor = :active_record

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

  config.use_text_errors = false

  config.exception_class_whitelist = []

  config.always_include_to_one_linkage_data = false
end
```

You may want a different configuration for your API. For more information check [this](https://github.com/cerebris/jsonapi-resources/#configuration).

### Requests & Responses

Here's some examples of requests – based on those sample [controllers](#routes--controllers) – and their respective JSON responses.

* [Collection](#collection)
* [Collection (options)](#collection-options)
* [Single record](#single-record)
* [Record (options)](#single-record-options)
* [Relationships (identifier objects)](#relationships-identifier-objects)
* [Nested resources](#nested-resources)

#### Collection

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

#### Collection (options)

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

#### Single record

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

#### Single record (options)

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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jsonapi-utils. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


