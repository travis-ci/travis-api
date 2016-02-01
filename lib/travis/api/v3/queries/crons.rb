module Travis::API::V3
  class Queries::Crons < Query

    def start(branch)
      raise ServerError, 'repository does not have a github_id'.freeze unless branch.repository.github_id

      payload = {
        repository: { id: branch.repository.github_id, owner_name: branch.repository.owner_name, name: branch.repository.name },
        branch:     branch.name
      }

      class_name, queue = Query.sidekiq_queue(:build_request)
      ::Sidekiq::Client.push('queue'.freeze => queue, 'class'.freeze => class_name, 'args'.freeze => [{type: 'cron'.freeze, payload: JSON.dump(payload)}])
      payload
    end
  end
end
