require 'travis/model'

class Membership < Travis::Model
  self.table_name = 'memberships'
  belongs_to :user
  belongs_to :organization
end

