class Repository < ActiveRecord::Base
  # has_many :commits
  # has_many :requests
  # has_many :branches
  # has_many :builds
  has_many :jobs
  has_many :permissions
  has_many :users,  through:   :permissions

  belongs_to :owner, polymorphic: true
end
