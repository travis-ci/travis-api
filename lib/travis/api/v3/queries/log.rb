require 'travis/logs_api'

module Travis::API::V3
  class Queries::Log < RemoteQuery

    def find(job)
      @job = job
      #check for the log in the Logs DB
      log = logs_model.find_by_job_id(@job.id)
      raise EntityMissing, 'log not found'.freeze if log.nil?
      #if the log has been archived, go to s3
      if log.archived_at
        content = fetch.first
        raise EntityMissing, 'could not retrieve log'.freeze if content.nil?
        body = content.body.force_encoding('UTF-8') unless content.body.nil?
        create_log_parts(log, body)
      #if log has been aggregated, look at log.content
      elsif log.aggregated_at
        create_log_parts(log, log.content)
      end
      log
    end

    def create_log_parts(log, content)
      return unless log.log_parts.respond_to?(:build)
      log.log_parts.build([{content: content, number: 0, created_at: log.created_at}])
    end

    def delete(user, job)
      @job = job
      log = logs_model.find_by_job_id(@job.id)
      raise EntityMissing, 'log not found'.freeze if log.nil?
      raise LogAlreadyRemoved if log.removed_at || log.removed_by
      raise JobUnfinished unless @job.finished_at?

      if log.archived_at
        archived_log = fetch
        remove(archived_log)
      end

      log.clear!(user)
      log
    end

    private

    def prefix
      "jobs/#{@job.id}/log.txt"
    end

    def s3_config
      conf = (config[:log_options][:s3] || {}).merge(bucket_name: bucket_name)
    end

    def bucket_name
      hostname('archive')
    end

    def hostname(name)
      "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
    end

    private def logs_model
      return Travis::API::V3::Models::RemoteLog if Travis.config.logs_api.enabled?
      Travis::API::V3::Models::Log
    end
  end
end
