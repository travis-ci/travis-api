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
      # https://stackoverflow.com/questions/10871131/how-to-use-or-condition-in-activerecord-query
      logins = list(created_by)
      created_builds = []

      logins.each do |login|
        if V3::Models::User.find_by_login(login.to_s)
          @sender_id = V3::Models::User.find_by_login(login.to_s).id
          @sender_type = 'User'
          created_builds << list.where(sender_id: @sender_id, sender_type: @sender_type)
        elsif V3::Models::Organization.find_by_login(login.to_s)
          @sender_id = V3::Models::Organization.find_by_login(login.to_s).id
          @sender_type = 'Organization'
          created_builds << list.where(sender_id: @sender_id, sender_type: @sender_type)
        else
          next
        end
      end
      raise EntityMissing, 'no builds found'.freeze unless created_builds != nil
      created_builds
    end
  end
end
