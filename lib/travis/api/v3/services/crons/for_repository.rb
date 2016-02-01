module Travis::API::V3
  class Services::Crons::ForRepository < Service
    paginate

    def run!
      query.find(find(:repository))
    end
  end
end
