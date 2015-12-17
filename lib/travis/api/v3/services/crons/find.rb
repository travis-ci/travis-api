module Travis::API::V3
  class Services::Crons::Find < Service
    paginate

    def run!
      query.find(find(:branch, find(:repository)))
    end
  end
end
