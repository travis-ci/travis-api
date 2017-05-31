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

    def filter(list)
      list = list.where(state:          list(state))          if state
      list = list.where(previous_state: list(previous_state)) if previous_state
      list = list.where(event_type:     list(event_type))     if event_type
      list = list.where(branch:         list(branch_name))    if branch_name
      list = for_owner(list, created_by) if created_by

      list = list.includes(:commit).includes(branch: :last_build).includes(:repository)
      list = list.includes(branch: { last_build: :commit }) if includes? 'build.commit'.freeze
      list = list.includes(:jobs) if includes? 'build.jobs'.freeze or includes? 'job'.freeze
      list
    end

    def for_owner(list, created_by)
      logins = list(created_by)

      users = V3::Models::User.where(login: logins)
      users.map! { |u| [u.id, 'User']}
      orgs = V3::Models::Organization.where(login: logins)
      orgs.map! { |o| [o.id, 'Organization']}

      owners = users + orgs
      raise NotFound, 'user or organization not found'.freeze if owners.count == 0

      owners.each do |owner|
        list = list.where("builds.sender_id = ? AND builds.sender_type = ?", owner[0], owner[1])
      end
      list
    end
  end
end
