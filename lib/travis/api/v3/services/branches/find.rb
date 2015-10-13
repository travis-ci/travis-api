module Travis::API::V3
  class Services::Branches::Find < Service
    params :exists_on_github, prefix: :branch
    paginate

    def run!
      query.find(find(:repository))
    end
  end
end
