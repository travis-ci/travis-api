module Travis::API::V3
  class Queries::Log < RemoteQuery
    def find(job)
      @job = job
      remote_log = Travis::RemoteLog.find_by_job_id(@job.id)
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
      remote_log = Travis::RemoteLog.find_by_job_id(@job.id)
      raise EntityMissing, 'log not found'.freeze if remote_log.nil?
      raise LogAlreadyRemoved if remote_log.removed_at || remote_log.removed_by
      raise JobUnfinished unless @job.finished_at?

      if remote_log.archived_at
        archived_log = fetch
        remove(archived_log)
      end

      remote_log.clear!(user)
      Travis::API::V3::Models::Log.new(remote_log: remote_log)
    end

    private

    def prefix
      "jobs/#{@job.id}/log.txt"
    end

    def s3_config
      super.merge(bucket_name: bucket_name)
    end

    def bucket_name
      hostname('archive')
    end

    def hostname(name)
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
    end
  end
end
