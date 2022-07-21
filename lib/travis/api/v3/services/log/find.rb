module Travis::API::V3
  class Services::Log::Find < Service
    params 'log.token'

    def run!
      job = Models::Job.find(params['job.id'])
      repo_can_write = !!job.repository.users.where(id: access_control.user.id, permissions: { push: true }).first

      log = query.find(repo_can_write, job)
      raise(NotFound, :log) unless access_control.visible? log
      result log
    end
  end
end
