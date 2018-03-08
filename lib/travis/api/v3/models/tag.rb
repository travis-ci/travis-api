module Travis::API::V3
  class Models::Tag < Model
    belongs_to :repository
    has_many   :builds,  -> { where('event_type = ?', 'push').order('builds.id DESC'.freeze) }, foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name]
    has_many   :commits, -> { order('commits.id DESC'.freeze) }, foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name]
  end
end
