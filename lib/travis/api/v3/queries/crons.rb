module Travis::API::V3
  class Queries::Crons < Query

    def find(repository)
      Models::Cron.where(:branch_id => repository.branches)
    end

    def start_all()
      started = []

      Models::Cron.all.each do |cron|
        if cron.next_enqueuing <= Time.now
          start(cron.branch)
          started.push cron
        end
      end

      started
    end

    def start(branch)
      raise ServerError, 'repository does not have a github_id'.freeze unless branch.repository.github_id

      user_id = branch.repository.users.detect { |u| u.github_oauth_token }.id

      payload = {
        repository: { id: branch.repository.github_id, owner_name: branch.repository.owner_name, name: branch.repository.name },
        branch:     branch.name,
        user:       { id: user_id }
      }

      class_name, queue = Query.sidekiq_queue(:build_request)
      ::Sidekiq::Client.push('queue'.freeze => queue, 'class'.freeze => class_name, 'args'.freeze => [{type: 'cron'.freeze, payload: JSON.dump(payload), credentials: {}}])
      payload
    end
  end
end
