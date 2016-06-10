class Repository < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  # has_many :commits
  # has_many :requests
  # has_many :branches
  # has_many :builds
  has_many :permissions
  has_many :users,  through:   :permissions
end
