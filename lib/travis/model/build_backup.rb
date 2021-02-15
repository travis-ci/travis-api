require 'travis/model'

class BuildBackup < Travis::Model
  include Travis::ScopeAccess

  belongs_to :repository
  validates :repository_id, presence: true
end
