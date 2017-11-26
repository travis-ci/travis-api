module Travis::API::V3
  class Models::Request < Model
    belongs_to :commit
    belongs_to :pull_request
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    has_many   :builds
    serialize  :config
    serialize  :payload

    def branch_name
      commit.branch if commit
    end

    def payload
      puts "[deprecated] Reading request.payload. Called from #{caller[0]}" # unless caller[0] =~ /(dirty.rb|request.rb|_spec.rb)/
      super
    end
  end
end
