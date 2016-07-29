module Travis::API::V3
  class Queries::Log < Query
    def find(job)
      #TODO check for the log in the DB, and then fetch it from S3 if not.
      
      job.log
    end
  end
end
