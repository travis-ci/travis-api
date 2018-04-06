module Travis::API::V3
  class Models::Installation < Model
    belongs_to :owner, polymorphic: true
  end
end
