module Travis::API::V3
  class Queries::Jobs < Query
    params :state, :created_by, :active, prefix: :job
    sortable_by :id
    default_sort "id:desc"

    ACTIVE_STATES = %w(created queued received started).freeze

    def find(build)
      relation = build.jobs
      relation = relation.includes(:commit) if includes? 'job.commit'.freeze
      relation
    end

    def filter(relation)
      relation = relation.where(state: ACTIVE_STATES) if bool(active)
      relation = relation.where(state: list(state))   if state
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
      ActiveRecord::Base.connection.execute "SET statement_timeout = '#{host_timeout}s';"
      fragment = "SELECT repository_id FROM permissions where user_id = #{user.id}"
      jobs = V3::Models::Job.where("EXISTS (#{fragment}) AND jobs.repository_id IN (#{fragment})")

      sort filter(jobs)
    end

    def stats_by_queue(queue)
      stats = Travis::API::V3::Models::Job.where(state: %w(queued started), queue: queue)
                                          .group(:state)
                                          .count
      Models::JobsStats.new(stats, queue)
    end

    def host_timeout
      return extended_timeout if slow_hosts.include?(host)
      default_timeout
    end

    def host
      @service.instance_variable_get(:@env)["HTTP_HOST"]
    end

    def slow_hosts
      (ENV['SLOW_HOSTS'] || "").split(',')
    end

    def default_timeout
      Travis.config.db.max_statement_timeout_in_seconds
    end

    def extended_timeout
      Travis.config.db.slow_host_max_statement_timeout_in_seconds
    end
  end
end
