module Travis::API::V3
  class Models::Broadcast < Model
    belongs_to :recipient, polymorphic: true
  end
end
