require 'active_record'

# Tables
ActiveRecord::Schema.define do
  create_table :categories, force: true do |t|
    t.string :title
    t.timestamps null: false
  end

  create_table :posts, force: true do |t|
    t.string   :title
    t.text     :body
    t.string   :content_type
    t.string   :hidden_field
    t.integer  :user_id
    t.integer  :category_id
    t.timestamps null: false
  end

  add_index :posts, :user_id
  add_index :posts, :category_id

  create_table :users, force: true do |t|
    t.string   :first_name
    t.string   :last_name
    t.boolean  :admin
    t.timestamps null: false
  end

  create_table :profiles, force: true do |t|
    t.references :user, index: true, foreign_key: true
    t.string   :nickname
    t.string   :location
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

class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'User', foreign_key: :user_id
  belongs_to :category
  validates :title, :body, :content_type, :hidden_field, :author, :category_id, presence: true
  validate :trip_hidden_error

  private

  def trip_hidden_error
    errors.add(:hidden_field, 'error was tripped') if title == 'Fail Hidden'
  end
end

class Category < ActiveRecord::Base
  has_many :posts
  validates :title, presence: true
end

class Profile < ActiveRecord::Base
  belongs_to :user
  validates :nickname, :location, presence: true
end
