module Travis::API::V3
  class Models::StarredRepository < Model
    has_many :repositories
  end
end