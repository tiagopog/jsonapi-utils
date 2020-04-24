require 'factory_bot'
require_relative './models'

# require 'byebug'; byebug

FactoryBot.define do
  factory :user, class: User do
    sequence(:id) { |n| n }
    sequence(:first_name) { |n| "User##{n}" }
    sequence(:last_name) { |n| "Lastname##{n}" }

    after(:create) { |user| create(:profile, user: user) }

    trait :with_posts do
      transient { post_count { 3 } }
      after(:create) do |user, e|
        create_list(:post, e.post_count, author: user)
      end
    end
  end

  factory :profile, class: Profile do
    user
    sequence(:id)       { |n| n }
    sequence(:nickname) { |n| "Nickname##{n}" }
    sequence(:location) { |n| "Location##{n}" }
  end

  factory :post, class: Post do
    association :author, factory: :user
    category

    sequence(:id) { |n| n }
    sequence(:title) { |n| "Title for Post #{n}" }
    sequence(:body) { |n| "Body for Post #{n}" }
    content_type { :article }
    hidden_field { 'It\'s a hidden field!' }
  end

  factory :category, class: Category do
    sequence(:title) { |n| "Title for Category #{n}" }
  end
end
