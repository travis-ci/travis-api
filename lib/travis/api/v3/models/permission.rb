module Travis::API::V3
  class Models::Permission < Model
    belongs_to :user
    belongs_to :repository
  end
end
