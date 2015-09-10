module Travis::API::V3
  class Services::Broadcasts::ForCurrentRepo < Service
    def run!
      query.for_repo(find(:repository))
    end
  end
end
