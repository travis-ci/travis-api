module Travis::API::V3
  class Models::Stage < Model
    belongs_to :build
    has_many :jobs
  end
end
