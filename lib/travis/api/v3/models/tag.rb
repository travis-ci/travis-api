module Travis::API::V3
  class Models::Tag < Model
    belongs_to :repository
    has_many   :builds,  -> { joins('inner join tags on builds.repository_id = tags.repository_id and  builds.branch = tags.name').where('event_type = ?', 'push').order('builds.id DESC'.freeze) }
    has_many   :commits, -> { joins('inner join tags on commits.repository_id = tags.repository_id and commits.branch = tags.name').order('commits.id DESC'.freeze) }
  end
end
