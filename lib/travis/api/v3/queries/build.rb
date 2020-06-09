require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'

module Travis::API::V3
  class Queries::Build < Query
    params :id, :cancel_all

    PRIORITY = { high: 5, low: -5, medium: nil }

    def find
      return Models::Build.find_by_id(id) if id
      raise WrongParams, 'missing build.id'.freeze
    end

    def cancel(user, build_id)
      raise BuildNotCancelable if %w(passed failed canceled errored).include? find.state

      payload = { id: build_id, user_id: user.id, source: 'api' }
      service = Travis::Enqueue::Services::CancelModel.new(user, { build_id: build_id })
      service.push("build:cancel", payload)
      payload
    end

    def restart(user)
      raise BuildAlreadyRunning if %w(received queued started).include? find.state

      service = Travis::Enqueue::Services::RestartModel.new(user, { build_id: id })
      payload = { id: id, user_id: user.id }

      restart_status = service.push("build:restart", payload)

      if restart_status == "abuse_detected"
        restart_status
      else
        payload
      end
    end

    def priority(user)
      raise NotFound, "Jobs are not found" if find.jobs.blank?
      find.jobs.update_all(priority: PRIORITY[:high])
      return if find.owner_type != "Organization"
      if cancel_all == "true"
        builds = find.owner.running_builds.select { |build| !build.high_priority? }
        builds.each { |build| cancel(user, build.id) } if builds
      end
    end
  end
end
