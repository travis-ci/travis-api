class Plan < ApplicationRecord
  belongs_to :subscription

  scope :current, -> { order('updated_at DESC').first }
end
