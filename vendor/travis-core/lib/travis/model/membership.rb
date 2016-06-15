require 'travis/model'

class Membership < Travis::Model
  belongs_to :user
  belongs_to :organization
end

