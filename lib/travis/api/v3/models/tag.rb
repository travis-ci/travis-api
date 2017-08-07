module Travis::API::V3
  class Models::Tag < Model
    belongs_to :repository
    has_many   :builds,  foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name], order: 'builds.id DESC'.freeze, conditions: { event_type: 'push' }
    has_many   :commits, foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name], order: 'commits.id DESC'.freeze
  end
end
