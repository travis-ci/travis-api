module Travis::API::V3
  class Queries::Jobs < Query
    params :state, :created_by, :active, prefix: :job
    sortable_by :id, :state
    default_sort "id:desc,state"

    ACTIVE_STATES = %w(created queued received started).freeze

    def find(build)
      relation = build.jobs
      relation = relation.includes(:commit) if includes? 'job.commit'.freeze
      relation
    end

    def filter(relation)
      relation = for_owner(relation)                  if created_by

      relation = relation.includes(:build)
      relation = relation.includes(:commit) if includes? 'job.commit'.freeze
      relation
    end

    def for_owner(relation)
      users = V3::Models::User.where(login: list(created_by)).pluck(:id)
      orgs = V3::Models::Organization.where(login: list(created_by)).pluck(:id)

      relation.joins(:build).where(
        %Q((builds.sender_type = 'User' AND builds.sender_id IN (?))
        OR (builds.sender_type = 'Organization' AND builds.sender_id IN (?))),
        users,
        orgs
      )
    end

    def for_user(user)
      set_custom_timeout(host_timeout)
      if ENV['TCIE_BETA_MOST_RECENT_JOBS_LW'] == 'true'
        jobs = V3::Models::Job.where("jobs.id in (select id from most_recent_job_ids_for_user_repositories_by_states_lw(#{user.id}, ?))", states)
      else
        jobs = V3::Models::Job.where("jobs.id in (select id from most_recent_job_ids_for_user_repositories_by_states(#{user.id}, ?))", states)
      end

      sort filter(jobs)
    end

    def stats_by_queue(queue)
      stats = Travis::API::V3::Models::Job.where(state: %w(queued started), queue: queue)
                                          .group(:state)
                                          .count
      Models::JobsStats.new(stats, queue)
    end

    private

    def states
      s = []
      s << ACTIVE_STATES if bool(active)
      s << list(state) if state
      return '' if s.empty?
      s.flatten.uniq.join(',')
    end
  end
end
