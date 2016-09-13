module Travis::API::V3
  class Queries::Log < Query
    require 'net/http'
    require 'uri'
    require 'aws/s3'

    FORMAT = "Log removed by %s at %s"

    def find(job)
      #check for the log in the Logs DB
      log = Models::Log.find_by_job_id(job.id)

      raise EntityMissing, 'log not found'.freeze if log.nil?
      #if the log has been archived, go to s3
      if log.archived_at
        ## if it's not there then fetch it from S3, and return it wrapped as a
        ## compatible log_parts object with a hard coded number (log_parts have a number)
        ## and a single log_part that contains all the log content
        archived_log_path = archive_url("/jobs/#{job.id}/log.txt")
        content = Net::HTTP.get(URI.parse(archived_log_path))
        log_part = Models::LogPart.new(log_id: log.id, content: content, number: 0, created_at: log.created_at)
        log_parts = []
        log_parts << log_part
        log.log_parts = log_parts
      end
      log
    end

    def archive_url(path)
      "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
    end

    def hostname(name)
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
    end

    def delete(user, job)
      log = Models::Log.find_by_job_id(job.id)
      raise EntityMissing, 'log not found'.freeze if log.nil?
      raise LogAlreadyRemoved if log.removed_at || log.removed_by
      raise JobUnfinished unless job.finished_at?

      if log.archived_at
        AWS.config(Travis::Logs.config.s3.to_hash.slice(:access_key_id, :secret_access_key))
        s3 = AWS::S3.new
        obj = s3.buckets["#{hostname('archive')}"].objects["jobs/#{job.id}/log.txt"]
        obj.delete
      end

      removed_at = Time.now

      message = FORMAT % [user.name, removed_at.utc]
      log.clear!(user, message)
      log
    end
  end
end
