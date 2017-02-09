require 's3'

module Travis::API::V3
  class Queries::Log < RemoteQuery

    def find(job)
      @job = job
      #check for the log in the Logs DB
      log = Models::Log.find_by_job_id(@job.id)
      raise EntityMissing, 'log not found'.freeze if log.nil?
      #if the log has been archived, go to s3
      if log.archived_at
        content = s3_config.buckets.find(bucket_name).objects.find(prefix).content
        p "#" * 60
        p content
        p bucket_name
        p "#" * 60
        create_log_parts(log, content)
      #if log has been aggregated, look at log.content
      elsif log.aggregated_at
        create_log_parts(log, log.content)
      end
      log
    end

    def create_log_parts(log, content)
      log.log_parts << Models::LogPart.new(log_id: log.id, content: content, number: 0, created_at: log.created_at)
    end

    def delete(user, job)
      @job = job
      log = Models::Log.find_by_job_id(@job.id)
      raise EntityMissing, 'log not found'.freeze if log.nil?
      raise LogAlreadyRemoved if log.removed_at || log.removed_by
      raise JobUnfinished unless @job.finished_at?

      remove if log.archived_at

      log.clear!(user)
      log
    end

    private

    def prefix
      "jobs/#{@job.id}/log.txt"
    end

    def bucket_name
      hostname('archive')
    end

    def hostname(name)
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
    end

    def s3_config
      S3::Service.new(:access_key_id => Travis.config.log_options.s3.access_key_id, :secret_access_key => Travis.config.log_options.s3.secret_access_key)
      #conf = config.logs_options.try(:s3) || {}
      #conf.merge!(bucket_name: bucket_name)
    end

  end
end
