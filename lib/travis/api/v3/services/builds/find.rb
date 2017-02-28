module Travis::API::V3
  class Services::Builds::Find < Service
    params :state, :event_type, :previous_state, prefix: :build
    params "branch.name"
    paginate

    def run!
      result query.find(find(:repository))
    end
  end
end
