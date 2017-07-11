class PullRequest < ActiveRecord::Base
  belongs_to :repository
  has_many :requests
  has_many :builds
end
