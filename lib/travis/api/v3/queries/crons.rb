module Travis::API::V3
  class Queries::Crons < Query

    def find(repository)
      Models::Cron.where(:branch_id => repository.branches)
    end

    def start_all()
      Models::Cron.all.select do |cron|
        begin
          @cron = cron
          start(cron) if cron.next_enqueuing <= Time.now
        rescue => e
          Raven.capture_exception(e, tags: { 'cron_id' => @cron.try(:id) })
          sleep(10) # This ensures the dyno does not spin down before the http request to send the error to sentry completes
          next
        end
      end
    end

    def start(cron)
      branch = cron.branch
      raise ServerError, 'repository does not have a github_id'.freeze unless branch.repository.github_id
      unless branch.exists_on_github
        cron.destroy
        return false
      end

      user_id = branch.repository.users.detect { |u| u.github_oauth_token }.try(:id)
      user_id ||= branch.repository.owner.id

      payload = {
        repository: { id: branch.repository.github_id, owner_name: branch.repository.owner_name, name: branch.repository.name },
        branch:     branch.name,
        user:       { id: user_id }
      }

      class_name, queue = Query.sidekiq_queue(:build_request)
      ::Sidekiq::Client.push('queue'.freeze => queue, 'class'.freeze => class_name, 'args'.freeze => [{type: 'cron'.freeze, payload: JSON.dump(payload), credentials: {}}])
      true
    end
  end
end
