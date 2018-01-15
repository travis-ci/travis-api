module Travis::API::V3
  class Models::Message < Model
    belongs_to :subject, polymorphic: true  
  end
end