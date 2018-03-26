module Travis::API::V3
  class Queries::Cron < Query
    params :id
    params :interval, :dont_run_if_recent_build_exists
    params :interval, :dont_run_if_recent_build_exists, prefix: :cron
    sortable_by :id

    def find
      return Models::Cron.find_by_id(id) if id
      raise WrongParams, 'missing cron.id'.freeze
    end

    def find_for_branch(branch)
      branch.cron
    end

    def create(branch)
      branch.cron.destroy unless branch.cron.nil?
      Models::Cron.create(branch: branch, interval: _interval, dont_run_if_recent_build_exists: _dont_run_if_recent_build_exists, active: true)
    end

    private

    def _interval
      cron_params.key?('interval') ? cron_params['interval'] : params['interval']
    end

    def _dont_run_if_recent_build_exists
      value = cron_params['dont_run_if_recent_build_exists'] || params['dont_run_if_recent_build_exists']
      value || false
    end

  end
end
