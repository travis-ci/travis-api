class Commit < ActiveRecord::Base
  belongs_to :repository
  belongs_to :last_build, class_name: 'Build'
  has_many   :builds
  has_many   :jobs
  has_one    :request
end
