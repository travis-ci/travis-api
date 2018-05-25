module Travis::API::V3
  class Services::Requests::Find < Service
    paginate
    def run!
      unfiltered = query.find(find(:repository))
      result access_control.visible_requests(unfiltered) 
    end
  end
end
