require 'factory_girl'

FactoryGirl.define do
  factory :post, class: Post do
    skip_create
    sequence(:id) { |n| n }
    sequence(:title) { |n| "Title for Post #{n}" }
    sequence(:body) { |n| "Body for Post #{n}" }

    trait :with_author do
      association :author, factory: :user
    end
  end

  factory :user, class: User do
    skip_create
    sequence(:id) {|n| n }
    sequence(:first_name) {|n| "User ##{n}"}
    sequence(:last_name) {|n| "Lastname ##{n}"}
  end
end
