require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'

module Travis::API::V3
  class Queries::Build < Query
    params :id

    def find
      return Models::Build.find_by_id(id) if id
      raise WrongParams, 'missing build.id'.freeze
    end

    def cancel(user)
      raise BuildNotCancelable if %w(passed failed canceled errored).include? find.state
      payload = { id: id, user_id: user.id, source: 'api' }
      if Travis::Features.owner_active?(:enqueue_to_hub, find.repository.owner)
        service = Travis::Enqueue::Services::CancelModel.new(user, { build_id: id })
        service.push("build:cancel", payload)
      else
        perform_async(:build_cancellation, payload)
      end
      payload
    end

    def restart(user)
      raise BuildAlreadyRunning if %w(received queued started).include? find.state
      if Travis::Features.owner_active?(:enqueue_to_hub, find.repository.owner)
        service = Travis::Enqueue::Services::RestartModel.new(user, { build_id: id })
        payload = { id: id, user_id: user.id }
        service.push("build:restart", payload)
      else
        payload = { id: id, user_id: user.id, source: 'api' }
        perform_async(:build_restart, payload)
      end
      payload
    end
  end
end
