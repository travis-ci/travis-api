module Travis::API::V3
  class Queries::Log < RemoteQuery
    def find_by_job_id(job_id)
      find Models::Job.find(job_id)
    end

    def find(job)
      @job = job
      remote_log = Travis::RemoteLog::Remote.new(platform: platform).find_by_job_id(platform_job_id)
      raise EntityMissing, 'log not found'.freeze if remote_log.nil?

      log = Travis::API::V3::Models::Log.new(remote_log: remote_log, job: job)
      # if the log has been archived, go to s3
      if log.archived?
        content = fetch.first
        raise EntityMissing, 'could not retrieve log'.freeze if content.nil?
        log.archived_content = content.body.force_encoding('UTF-8') unless content.body.nil?
      end
      log
    end

    def delete(user, job)
      @job = job
      remote_log = Travis::RemoteLog::Remote.new(platform: platform).find_by_job_id(platform_job_id)
      raise EntityMissing, 'log not found'.freeze if remote_log.nil?
      raise LogAlreadyRemoved if remote_log.removed_at || remote_log.removed_by
      raise JobUnfinished unless @job.finished_at?

      if remote_log.archived_at
        archived_log = fetch
        remove(archived_log)
      end

      remote_log.clear!(user)
      Travis::API::V3::Models::Log.new(remote_log: remote_log, job: @job)
    end

    private

    def prefix
      "jobs/#{platform_job_id}/log.txt"
    end

    def s3_config
      platform_prefix = "#{platform}_" unless platform == :default
      config["#{platform_prefix}#{main_type}_options".to_sym][:s3].merge(bucket_name: bucket_name)
    end

    def bucket_name
      platform_prefix = "#{platform}_" unless platform == :default
      config["#{platform_prefix}#{main_type}_options".to_sym][:s3][:bucket_name] || hostname('archive')
    end

    def hostname(name)
      host = platform == :default ? Travis.config.host : Travis.config["#{platform}_host"]
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{host.split('.')[-2, 2].join('.')}"
    end

    def platform
      return :default if deployed_on_org?
      return :fallback if @job.migrated? && !@job.restarted_post_migration?
      :default
    end

    def platform_job_id
      return @job.org_id if @job.migrated? && !@job.restarted_post_migration?
      @job.id
    end

    def deployed_on_org?
      ENV["TRAVIS_SITE"] == "org"
    end
  end
end
