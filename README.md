# JSONAPI::Utils

JSON::Utils is a simple way to get a full-featured [JSON API](jsonapi.org) serialization in your
controller's responses. This gem combine some functionalities from the awesome gem
[jsonapi-resources](https://github.com/cerebris/jsonapi-resources) into a Rails-native way to render data.

Required doc:

* Describe something about the awesome `jsonapi-resources` gem
* Describe how it's easy to serialize JSON API-based responses using the `jsonapi-utils` gem
* JSONAPI::Utils#jsonapi_render (show options like `json`, `resource`, `model`, `scope` and `count`)
* JSONAPI::Utils#jsonapi_serialize
* Example of a model
* Example of a resource
* Example of a base controller and another whatever controller

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi-utils'
```

And then execute:

```shell
$ bundle
```

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

Let's define our routes using the `jsonapi_resources` macro provied by the `jsonapi-resources` gem:

```ruby
Rails.application.routes.draw do
  jsonapi_resources :users do
    jsonapi_resources :posts
  end
end
```

And a base controller to include the features from `jsonapi-resources` and `jsonapi-utils`:

```ruby
# app/controllers/base_controller.rb
class BaseController < JSONAPI::ResourceController
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
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
    users = User.all
    jsonapi_render json: users, options: { count: users.size }
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
    jsonapi_render json: @user.posts, options: { count: @user.posts.size }
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

### Requests

TODO: show some examples of requests here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jsonapi-utils. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


