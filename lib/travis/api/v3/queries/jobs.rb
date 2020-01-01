module Travis::API::V3
  class Queries::Jobs < Query
    params :state, :created_by, :active, prefix: :job
    sortable_by :id
    default_sort "id:desc"

    ACTIVE_STATES = %w(created queued received started).freeze
    REPOSITORIES_CHUNK_SIZE = 100.freeze

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
      repositories_in_chunks = []
      jobs = []

      ActiveRecord::Base.connection.execute "SET statement_timeout = '300s';"
      repositories = V3::Models::Permission.where(["permissions.user_id = ?", user.id]).pluck(:repository_id)
      repositories.each_slice(REPOSITORIES_CHUNK_SIZE){|chunk| repositories_in_chunks << chunk}
      repositories_in_chunks.each do |repos|
        jobs.concat(V3::Models::Job.where(["jobs.repository_id IN (?)", repos]))
      end
      sort filter(jobs)
    end

    def stats_by_queue(queue)
      stats = Travis::API::V3::Models::Job.where(state: %w(queued started), queue: queue)
                                          .group(:state)
                                          .count
      Models::JobsStats.new(stats, queue)
    end
  end
end
