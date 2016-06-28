class Request < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  belongs_to :commit
  belongs_to :repository
  has_many   :builds

  serialize  :payload
end
