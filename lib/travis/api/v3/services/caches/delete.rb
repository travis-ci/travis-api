module Travis::API::V3
  class Services::Caches::Delete < Service
    params :name, :branch

    def run!
      result query.delete(find(:repository))
    end
  end
end
