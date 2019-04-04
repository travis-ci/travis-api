module Travis::API::V3
  class Services::Requests::Find < Service
    paginate
    def run!
      repository = find(:repository)
      unfiltered = query.find(repository)
      result access_control.visible_requests(unfiltered, repository.id)
    end
  end
end
