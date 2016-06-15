class Repository < ActiveRecord::Base
  has_many :jobs
  has_many :permissions
  has_many :users,   through:     :permissions
  belongs_to :owner, polymorphic: true
end
