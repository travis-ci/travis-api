module Travis::API::V3
  class Models::Branch < Model
    belongs_to :repository
    belongs_to :last_build, class_name: 'Travis::API::V3::Models::Build'.freeze
    has_one    :cron,   dependent: :destroy

    def builds
      Travis::API::V3::Models::Build.all
        .joins("inner join branches on builds.repository_id = #{repository_id} and '#{name}' = builds.branch")
        .where(event_type: 'push')
        .order('builds.id DESC'.freeze)
    end

    def commits
      Travis::API::V3::Models::Commit.all
        .joins("inner join branches on commits.repository_id = #{repository_id} and '#{name}' = commits.branch")
        .order('commits.id DESC'.freeze)
    end

    def default_branch
      name == repository.default_branch_name
    end
  end
end
