module Travis::API::V3
  class Queries::Jobs < Query
    #params :state, :event_type, :previous_state, prefix: :job
    #params :name, prefix: :branch, method_name: :branch_name

    #sortable_by :id, :started_at, :finished_at

    def find(build)
      sort filter(build.jobs)
    end

    def filter(list)
      #list = list.where(state:          list(state))          if state
      #list = list.where(previous_state: list(previous_state)) if previous_state
      #list = list.where(event_type:     list(event_type))     if event_type
      #list = list.where(branch:         list(branch_name))    if branch_name

      list
    end
  end
end
