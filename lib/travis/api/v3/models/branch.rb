module Travis::API::V3
  class Models::Branch < Model
    belongs_to :repository
    belongs_to :last_build, class_name: 'Travis::API::V3::Models::Build'.freeze
    has_many   :builds,  foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name], order: 'id DESC'.freeze
    has_many   :commits, foreign_key: [:repository_id, :branch], primary_key: [:repository_id, :name], order: 'id DESC'.freeze
  end
end
