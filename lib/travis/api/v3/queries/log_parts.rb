module Travis::API::V3
  class Queries::LogParts < RemoteQuery
    def parts(job, params)
      @job = job
      content = (params['content'] || 'true') == 'true'
      remote_log = remote_log_svc.find_parts_by_job_id(
        platform_job_id,
        after: params['after'],
        part_numbers: params['part_numbers'],
        require_all: (params['require_all'] || 'true') == 'true',
        content: content
      )
      raise EntityMissing, 'log not found'.freeze if remote_log.nil?

      Travis::API::V3::Models::LogParts.new(remote_log: remote_log, job: job, content: content)
    end

    private

    def remote_log_svc
      @remote_log_svc ||= Travis::RemoteLog::Remote.new(platform: platform)
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
