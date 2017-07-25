module Travis::API::V3
  class Queries::Stages < Query

    def find(build)
      build.stages
    end
  end
end
