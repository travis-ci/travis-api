module Travis::API::V3
  class Models::Request < Model
    belongs_to :commit
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    has_many   :builds
    serialize  :config
    serialize  :payload
  end
end
