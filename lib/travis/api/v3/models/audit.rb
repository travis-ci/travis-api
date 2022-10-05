module Travis::API::V3
  class Models::Audit < Model
    belongs_to :owner, polymorphic: true
    belongs_to :source, polymorphic: true
  end
end
