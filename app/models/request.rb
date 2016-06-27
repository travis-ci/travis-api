class Request < ActiveRecord::Base
  belongs_to :commit
  belongs_to :repository
  has_many   :builds
end
