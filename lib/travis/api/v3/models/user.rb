module Travis::API::V3
  class Models::User < Model
    has_many :emails
  end
end
