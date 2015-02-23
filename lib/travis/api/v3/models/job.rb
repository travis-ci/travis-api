module Travis::API::V3
  class Models::Job < Model
    has_one    :log, dependent: :destroy
    belongs_to :repository
    belongs_to :commit
    belongs_to :build, autosave: true, foreign_key: 'source_id'
    belongs_to :owner, polymorphic: true
    serialize :config
  end
end
