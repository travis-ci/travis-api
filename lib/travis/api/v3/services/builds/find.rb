module Travis::API::V3
  class Services::Builds::Find < Service
    params :state, :event_type, :previous_state, :created_by, prefix: :build
    params "branch.name"
    paginate

    def run!
      repository = find(:repository)
      unfiltered = query.find(repository)
      result access_control.visible_builds(unfiltered, repository.id)
    end
  end
end
