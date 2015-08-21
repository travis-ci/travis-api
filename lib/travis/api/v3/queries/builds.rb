module Travis::API::V3
  class Queries::Builds < Query
    params :state, :event_type, :previous_state, prefix: :build

    def find(repository)
      filter(repository.builds)
    end

    def filter(list)
      list = list.where(state:          list(state))          if state
      list = list.where(previous_state: list(previous_state)) if previous_state
      list = list.where(event_type:     list(state))          if event_type

      list = list.includes(:commit).includes(branch: :last_build).includes(:repository)
      list = list.includes(branch: { last_build: :commit }) if includes? 'build.commit'.freeze
      list
    end
  end
end
