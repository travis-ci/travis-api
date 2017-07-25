module Travis::API::V3
  class Queries::Jobs < Query
    def find(build)
      build.jobs
    end
  end
end
