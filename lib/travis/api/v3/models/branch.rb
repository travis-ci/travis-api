module Travis::API::V3
  class Models::Branch < Model

    self.table_name = 'branches'

    belongs_to :repository
    belongs_to :last_build, class_name: 'Travis::API::V3::Models::Build'.freeze
    has_many   :builds,  -> { where(event_type: 'push').order('builds.id DESC'.freeze) }, foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name]
    has_many   :commits, -> { order('commits.id DESC'.freeze) }, foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name]
    has_one    :cron,   dependent: :destroy

    def default_branch
      name == repository.default_branch_name
    end
  end
end
