module Travis::API::V3
  class Queries::Stages < Query

    def find(build)
      sort filter(build.stages)
    end

    def filter(list)
      list
    end
  end
end
