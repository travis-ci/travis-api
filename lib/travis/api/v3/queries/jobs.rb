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
      repositories = V3::Models::Permission.where(["permissions.user_id = ?", user.id]).pluck(:repository_id)
      jobs = V3::Models::Job.where(["repository_id IN (?)", repositories])
      sort filter(jobs)
    end
  end
end
