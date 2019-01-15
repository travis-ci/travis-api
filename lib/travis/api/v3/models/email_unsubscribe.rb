module Travis::API::V3
  class Models::EmailUnsubscribe < Model
    belongs_to :user
    belongs_to :repository

    validates :repository, uniqueness: { scope: :user }
  end
end
