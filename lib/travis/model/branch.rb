require 'travis/model'

class Branch < Travis::Model
  include Travis::ScopeAccess

  belongs_to :repository
  belongs_to :last_build, class_name: 'Build'
end
