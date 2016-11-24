module Travis::API::V3
  class Queries::Cron < Query
    params :id

    sortable_by :id

    def find
      return Models::Cron.find_by_id(id) if id
      raise WrongParams, 'missing cron.id'.freeze
    end

    def find_for_branch(branch)
      branch.cron
    end

    def create(branch, interval, dont_run_if_recent_build_exists)
      branch.cron.destroy unless branch.cron.nil?
      Models::Cron.create(branch: branch, interval: interval, dont_run_if_recent_build_exists: dont_run_if_recent_build_exists)
    end
  end
end
