module Travis::API::V3
  class Models::Commit < Model
    belongs_to :repository
    has_one    :request
  end
end
