module Travis::API::V3
  class Services::Crons::ForRepository < Service
    paginate

    def run!
      repo = find(:repository)
      result query.find(repo)
    end
  end
end
