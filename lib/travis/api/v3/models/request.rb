module Travis::API::V3
  class Models::Request < Model
    BRANCH_REF = %r{refs/heads/(.*?)$}

    belongs_to :commit
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    has_many   :builds
    serialize  :config
    serialize  :payload

    def branch_name
      ref =~ BRANCH_REF and $1
    end

    def ref
      payload['ref'] if payload
    end
  end
end
