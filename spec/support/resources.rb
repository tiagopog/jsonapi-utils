class CategoryResource < JSONAPI::Resource
  attribute :title
  has_many :posts
end

class PostResource < JSONAPI::Resource
  attributes :title, :content_type, :body
  has_one :author
  has_one :category
end

class AuthorResource < JSONAPI::Resource
  model_name 'Person'
  has_many :posts
end

module V2
  class PostResource < ::PostResource; end
end

class UserResource < JSONAPI::Resource
  attributes :first_name, :last_name, :full_name

  has_one :profile, foreign_key_on: :related
  has_many :posts

  filters :first_name
  custom_filters :full_name

  def full_name
    "#{@model.first_name} #{@model.last_name}"
  end
end

class ProfileResource < JSONAPI::Resource
  attributes :nickname, :location
  has_one :user, class_name: 'User', foreign_key: 'user_id'
end
