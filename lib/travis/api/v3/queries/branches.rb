module Travis::API::V3
  class Queries::Branches < Query
    params :exists_on_github, prefix: :branch

    sortable_by :name,
      last_build:       "builds.started_at".freeze,
      exists_on_github: sort_condition(:exists_on_github),
      default_branch:   sort_condition(name: "repositories.default_branch")

    default_sort "last_build:desc"

    def find(repository)
      sort(filter(repository.branches), repository: repository)
    end

    def sort_by(collection, field, repository: nil, **options)
      return super unless field == "default_branch".freeze

      if repository
        options[:sql] = sort_condition(name: quote(repository.default_branch_name))
      else
        collection    = collection.joins(:repository)
      end

      super(collection, field, **options)
    end

    def filter(list)
      list = list.where(exists_on_github: bool(exists_on_github)) unless exists_on_github.nil?
      list
    end
  end
end
