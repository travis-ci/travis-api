require 'gh'
require 'travis/model'

class OwnerGroup < Travis::Model
  belongs_to :owner, polymorphic: true
end