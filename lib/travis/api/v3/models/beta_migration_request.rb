module Travis::API::V3
  class Models::BetaMigrationRequest < Model
    belongs_to    :owner, polymorphic: true
    has_many      :organizations
  end
end
