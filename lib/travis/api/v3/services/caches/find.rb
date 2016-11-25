module Travis::API::V3
  class Services::Caches::Find < Service
    params :match, :branch

    def run!
      query.find(find(:repository))
    end
  end
end
