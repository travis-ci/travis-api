module Travis::API::V3
  class Models::KeyPair < Travis::Settings::Model
    attribute :id, String
    attribute :repository_id, Integer
  end
end
