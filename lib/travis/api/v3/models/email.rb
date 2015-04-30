module Travis::API::V3
  class Models::Email < Model
    belongs_to :user
  end
end
