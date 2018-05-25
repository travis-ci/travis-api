module Travis::API::V3
  class Services::Builds::Find < Service
    params :state, :event_type, :previous_state, :created_by, prefix: :build
    params "branch.name"
    paginate

    def run!
      unfiltered = query.find(find(:repository))
      result access_control.visible_builds(unfiltered)
    end
  end
end
