require 'gh'
require 'travis/model'

class OwnerGroup < Travis::Model
  self.table_name = 'owner_groups'
  belongs_to :owner, polymorphic: true
end
