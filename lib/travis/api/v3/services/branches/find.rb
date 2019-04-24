module Travis::API::V3
  class Services::Branches::Find < Service
    params :exists_on_github, :name_filter, prefix: :branch
    paginate

    def run!
      result query.find(find(:repository))
    end
  end
end
