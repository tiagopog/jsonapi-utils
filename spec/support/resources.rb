class PostResource < JSONAPI::Resource
  attributes :title, :body
  has_one :author
end

module V2
  class PostResource < ::PostResource; end
end

class UserResource < JSONAPI::Resource
  attributes :first_name, :last_name, :full_name

  has_one :profile, class_name: 'Profile'
  has_many :posts

  filters :first_name
  custom_filters :full_name

  def full_name
    "#{@model.first_name} #{@model.last_name}"
  end
end

class ProfileResource < JSONAPI::Resource
  attributes :nickname
  has_one :user, class_name: 'User', foreign_key: 'user_id'
end
