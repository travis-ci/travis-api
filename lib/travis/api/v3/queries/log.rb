module Travis::API::V3
  class Queries::Log < Query
    def find(job)
      job.log
    end
  end
end
