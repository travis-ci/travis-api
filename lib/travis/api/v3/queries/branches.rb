module Travis::API::V3
  class Queries::Branches < Query
    params :exists_on_github, prefix: :branch
    experimental_params :name_filter, prefix: :branch

    sortable_by :name,
      last_build:       "builds.id".freeze,
      exists_on_github: sort_condition(:exists_on_github),
      default_branch:   sort_condition(name: "repositories.default_branch"),
      name_filter:      "name_filter"

    default_sort "default_branch,exists_on_github,last_build:desc"

    experimental_sortable_by :name_filter

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

      if name_filter
        query = name_filter.strip
        sql_phrase = query.empty? ? '%' : "%#{query.split('').join('%')}%"

        query = ActiveRecord::Base.sanitize(query)

        list = list.where(["(lower(branches.name)) LIKE ?", sql_phrase])
      end

      list
    end
  end
end
