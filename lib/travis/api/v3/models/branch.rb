module Travis::API::V3
  class Models::Branch < Model
    belongs_to :repository
    belongs_to :last_build, class_name: 'Travis::API::V3::Models::Build'.freeze
    has_many   :builds,  -> { where(event_type: 'push').joins('inner join branches on builds.repository_id = branches.repository_id and branches.name = builds.branch').order('builds.id DESC'.freeze) }
    has_many   :commits, -> { order('commits.id DESC'.freeze).joins('inner join branches on commits.repository_id = branches.repository_id and branches.name = commits.branch') }
    has_one    :cron,   dependent: :destroy

    def default_branch
      name == repository.default_branch_name
    end
  end
end
