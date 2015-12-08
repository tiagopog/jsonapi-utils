require 'factory_girl'

FactoryGirl.define do
  factory :post, class: Post do
    association :author, factory: :user

    sequence(:id) { |n| n }
    sequence(:title) { |n| "Title for Post #{n}" }
    sequence(:body) { |n| "Body for Post #{n}" }
  end

  factory :user, class: User do
    sequence(:id) {|n| n }
    sequence(:first_name) {|n| "User ##{n}"}
    sequence(:last_name) {|n| "Lastname ##{n}"}

    trait :with_posts do
      transient { post_count 2 }
      after(:create) do |user, e|
        create_list(:post, e.post_count, author: user)
      end
    end
  end
end
