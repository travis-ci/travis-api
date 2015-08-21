module Travis::API::V3
  class Services::Requests::Find < Service
    def run!
      query.find(find(:repository))
    end
  end
end
