module Travis::API::V3
  class Queries::Builds < Query
    params :state, :event_type, :previous_state, :created_by, prefix: :build
    params :name, prefix: :branch, method_name: :branch_name

    sortable_by :id, :started_at, :finished_at

    def find(repository)
      sort filter(repository.builds)
    end

    def active_from(repositories)
      V3::Models::Build.where(
        repository_id: repositories.pluck(:id),
        state: ['created'.freeze, 'started'.freeze]
      ).includes(:active_jobs)
    end

    def filter(relation)
      relation = relation.where(state:          list(state))          if state
      relation = relation.where(previous_state: list(previous_state)) if previous_state
      relation = relation.where(event_type:     list(event_type))     if event_type
      relation = relation.where(branch:         list(branch_name))    if branch_name
      relation = for_owner(relation)                                  if created_by

      relation = relation.includes(:commit).includes(branch: :last_build).includes(:repository)
      relation = relation.includes(branch: { last_build: :commit }) if includes? 'build.commit'.freeze
      relation = relation.includes(:jobs) if includes? 'build.jobs'.freeze or includes? 'job'.freeze
      relation
    end

    def for_owner(relation)
      users = V3::Models::User.where(login: list(created_by)).pluck(:id)
      orgs = V3::Models::Organization.where(login: list(created_by)).pluck(:id)

      relation.where(%Q((builds.sender_type = 'User' AND builds.sender_id IN (?))
                    OR (builds.sender_type = 'Organization' AND builds.sender_id IN (?))), users, orgs)
    end

    def for_user(user)
      V3::Models::Build.where(
        sender_id: user.id,
        sender_type: 'User')
    end
  end
end
