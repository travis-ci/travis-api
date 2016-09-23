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
        content = s3.find_log(job.id).force_encoding("utf-8")
        log_part = Models::LogPart.new(log_id: log.id, content: content, number: 0, created_at: log.created_at)
        log_parts = []
        log_parts << log_part
        log.log_parts = log_parts
      end
      log
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
        s3.delete_log(job.id)
      end

      removed_at = Time.now

      message = FORMAT % [user.name, removed_at.utc]
      log.clear!(user, message)
      log
    end

    def s3
      @s3 ||= S3.new(hostname('archive'))
    end

    class S3
      def initialize(bucket_name)
        AWS.config(Travis.config.s3.to_hash.slice(:access_key_id, :secret_access_key))
        @s3 = AWS::S3.new
        @bucket_name = bucket_name
      end

      def find_log(job_id)
        obj = @s3.buckets["#{@bucket_name}"].objects["jobs/#{job_id}/log.txt"]
        obj.read
      end

      def delete_log(job_id)
        obj = @s3.buckets["#{@bucket_name}"].objects["jobs/#{job_id}/log.txt"]
        obj.delete
      end
    end

  end
end
