class TodoItem < ActiveRecord::Base
  belongs_to :todo_list

  default_scope { order(:due_date) }

  scope :completed, -> { where(completed: true) }
end
