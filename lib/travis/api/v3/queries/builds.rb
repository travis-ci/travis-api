module Travis::API::V3
  class Queries::Builds < Query
    params :state, :event_type, :previous_state, prefix: :build
    params :name, prefix: :branch, method_name: :branch_name

    sortable_by :id, :started_at, :finished_at

    def find(repository)
      sort filter(repository.builds)
    end

    def filter(list)
      list = list.where(state:          list(state))          if state
      list = list.where(previous_state: list(previous_state)) if previous_state
      list = list.where(event_type:     list(event_type))     if event_type
      list = list.where(branch:         list(branch_name))    if branch_name

      list = list.includes(:commit).includes(branch: :last_build).includes(:repository)
      list = list.includes(branch: { last_build: :commit }) if includes? 'build.commit'.freeze
      list = list.includes(:jobs) if includes? 'build.jobs'.freeze or includes? 'job'.freeze
      list
    end
  end
end
