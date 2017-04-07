require 'travis/config/defaults'

module Travis::API::V3
  class Models::Job < Model

    self.inheritance_column = :_type_disabled

    belongs_to :repository
    belongs_to :commit
    belongs_to :build, autosave: true, foreign_key: 'source_id'
    belongs_to :stage
    belongs_to :owner, polymorphic: true
    serialize :config
    serialize :debug_options

    def log
      @log ||= Travis::RemoteLog.find_by_job_id(id)
    end
  end
end
