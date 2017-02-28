module Travis::API::V3
  class Services::Requests::Find < Service
    paginate
    def run!
      result query.find(find(:repository))
    end
  end
end
