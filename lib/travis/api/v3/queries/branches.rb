module Travis::API::V3
  class Queries::Branches < Query
    params :exists_on_github, prefix: :branch

    sortable_by :name,
      last_build: "builds.started_at".freeze,
      exists_on_github: "(case when branches.exists_on_github then 1 else 2 end)".freeze

    default_sort "last_build:desc"

    def find(repository)
      sort filter(repository.branches)
    end

    def filter(list)
      list = list.where(exists_on_github: bool(exists_on_github)) unless exists_on_github.nil?
      list
    end
  end
end
