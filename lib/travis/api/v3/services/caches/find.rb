module Travis::API::V3
  class Services::Caches::Find < Service
    params :name, :branch

    def run!
      result query.find(find(:repository))
    end
  end
end
