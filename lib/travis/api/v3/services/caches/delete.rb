module Travis::API::V3
  class Services::Caches::Delete < Service
    params :match, :branch

    def run!
      query.delete(find(:repository))
    end
  end
end
