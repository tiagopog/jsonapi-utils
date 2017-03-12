require 'active_record'

# Tables
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string   :title
    t.text     :body
    t.integer  :user_id
    t.timestamps null: false
  end

  add_index :posts, :user_id

  create_table :users, force: true do |t|
    t.string   :first_name
    t.string   :last_name
    t.boolean  :admin
    t.timestamps null: false
  end

  create_table :profiles, force: true do |t|
    t.string :nickname
    t.references :user, index: true, foreign_key: true
    t.timestamps null: false
  end
end

# Models
class User < ActiveRecord::Base
  has_one :profile
  has_many :posts

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end

class Profile < ActiveRecord::Base
  belongs_to :user
end

class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'
  validates :title, :body, :author, presence: true
end
