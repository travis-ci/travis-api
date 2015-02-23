module Travis::API::V3
  class Models::Build < Model
    belongs_to :repository
    belongs_to :commit
    belongs_to :request
    belongs_to :repository, autosave: true
    belongs_to :owner, polymorphic: true
    has_many   :jobs, as: :source, order: :id, dependent: :destroy
  end
end
