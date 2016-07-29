module Travis::API::V3
  class Queries::Log < Query
    def find(job)
      #TODO check for the log in the DB, if it's not there then fetch it from S3.
      log = Models::Log.find_by_job_id
      #if the log exists and has not bee archived yet, then collect the log_parts and return the contents
      unless log.nil? || !log.archived_at.nil?
        log_parts = Models::Log::Part.where(log_id: log.id)
        log_parts.each { |log_part| contents << log_part.content }
        contents
      else
        #go look in S3
      end
    end
  end
end
