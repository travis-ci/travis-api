module Travis::API::V3
  class Services::Caches::Delete < Service
    params :match, :branch

    def run!
      result query.delete(find(:repository))
    end
  end
end
