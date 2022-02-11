module Travis::API::V3
  class Models::Tag < Model
    belongs_to :repository

    def builds
      Travis::API::V3::Models::Build.all
        .joins("inner join tags on builds.repository_id = #{repository_id} and  builds.branch = '#{name}'")
        .where('event_type = ?', 'push').order('builds.id DESC'.freeze)
    end

    def commits
      Travis::API::V3::Models::Commit.all
        .joins("inner join tags on commits.repository_id = #{repository_id} and commits.branch = '#{name}'")
        .order('commits.id DESC'.freeze)
    end
  end
end
