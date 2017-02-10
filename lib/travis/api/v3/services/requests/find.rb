module Travis::API::V3
  class Services::Requests::Find < Service
    paginate
    def run! #2
      query.find(find(:repository))
    end
  end
end
