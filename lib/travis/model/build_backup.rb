require 'travis/model'

class BuildBackup < Travis::Model
  self.table_name = 'build_backups'
  include Travis::ScopeAccess

  belongs_to :repository
  validates :repository_id, presence: true
end
