module Travis::API::V3
  class Models::PullRequest < Model
    belongs_to :repository
    has_many   :requests
    has_many   :builds
    serialize  :config
    serialize  :payload

    def branch_name
      commit.branch if commit
    end

    def payload
      puts "[deprectated] Reading request.payload. Called from #{caller[0]}" # unless caller[0] =~ /(dirty.rb|request.rb|_spec.rb)/
      super
    end
  end
end
