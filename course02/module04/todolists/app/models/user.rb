class User < ActiveRecord::Base
  has_one :profile, dependent: :destroy
  has_many :todo_lists, dependent: :destroy
  has_many :todo_items, through: :todo_lists, source: :todo_items

  has_secure_password

  validates_presence_of :username

  def get_completed_count
    todo_items.completed.count
  end
end
