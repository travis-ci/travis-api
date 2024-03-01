module Travis::API::V3
  class Queries::Repositories < Query
    params :active, :private, :starred, :managed_by_installation, :active_on_org, prefix: :repository
    experimental_params :name_filter, prefix: :repository
    experimental_params :slug_filter, prefix: :repository
    sortable_by :id, :github_id, :vcs_id, :owner_name, :name, active: sort_condition(:active),
                :'default_branch.last_build' => "branches.last_build_id %{order} NULLS LAST",
                :current_build => "repositories.current_build_id %{order} NULLS LAST",
                :name_filter   => "name_filter",
                :slug_filter   => "slug_filter"

    # this is a hack for a bug in AR that generates invalid query when it tries
    # to include `current_build` and join it at the same time. We don't actually
    # need the join, but it will be automatically added, because `current_build`
    # is an association. This prevents adding the join. We will probably be able
    # to remove it once we move to newer AR versions
    prevent_sortable_join :current_build
    experimental_sortable_by :current_build, :name_filter
    experimental_sortable_by :current_build, :slug_filter

    def for_member(user, **options)
      all(user: user, **options).joins(:users).where(users: user_condition(user), invalidated_at: nil)
    end

    def for_owner(owner, **options)
      filter(owner.repositories, **options)
    end

    def all(**options)
      filter(Models::Repository, **options)
    end

    def filter(list, user: nil)
      list = list.where(invalidated_at: nil)
      list = list.where(active:  bool(active))  unless active.nil?
      list = list.where(private: bool(private)) unless private.nil?
      list = list.includes(:owner) if includes? 'repository.owner'.freeze
      list = list.where("managed_by_installation_at #{bool(managed_by_installation) ? 'IS NOT' : 'IS'} NULL") unless managed_by_installation.nil?
      list = list.where(active_on_org: bool(active_on_org) ? true : [false, nil]) unless active_on_org.nil?

      if user and not starred.nil?
        if bool(starred)
          list = list.joins(:stars).where(stars: { user_id: user.id })
        elsif user.starred_repository_ids.any?
          list = list.where("repositories.id NOT IN (?)", user.starred_repository_ids)
        end
      end

      if includes? 'repository.last_build'.freeze or includes? 'build'.freeze
        list = list.includes(:last_build)
        list = list.includes(last_build: :commit) if includes? 'build.commit'.freeze
      end

      if name_filter
        query = name_filter.strip.downcase
        sql_phrase = query.empty? ? '%' : "%#{query.split('').join('%')}%"

        query = ActiveRecord::Base.sanitize_sql(query)

        list = list.where(["(lower(repositories.name)) LIKE ?", sql_phrase])
        list = list.select("repositories.*, similarity(lower(repositories.name), '#{query}') as name_filter")
      end

      if slug_filter
        query = slug_filter.strip.downcase
        sql_phrase = query.empty? ? '%' : "%#{query.split('').join('%')}%"

        query = ActiveRecord::Base.sanitize_sql(query)

        list = list.where(["(lower(repositories.owner_name) || '/'
                              || lower(repositories.name)) LIKE ?", sql_phrase])
        list = list.select("repositories.*, similarity(lower(repositories.owner_name) || '/'
                              || lower(repositories.name), '#{query}') as slug_filter")
      end

      if includes? 'build.commit'.freeze
        list = list.includes(default_branch: { last_build: :commit })
      else
        list = list.includes(default_branch: :last_build)
      end
      list = list.includes(current_build: [:repository, :branch, :commit, :stages]) if includes? 'repository.current_build'.freeze
      sort list
    end

    def sort(*args)
      if params['sort_by']
        sort_by_list = list(params['sort_by'])
        name_filter_condition = lambda { |sort_by| sort_by =~ /^name_filter/ }
        slug_filter_condition = lambda { |sort_by| sort_by =~ /^slug_filter/ }

        if name_filter.nil? && sort_by_list.find(&name_filter_condition)
          warn "name_filter sort was selected, but name_filter param is not supplied, ignoring"

          # TODO: it would be nice to have better primitives for sorting so
          # manipulation is easier than that
          params['sort_by'] = sort_by_list.reject(&name_filter_condition).join(',')
        end

        if slug_filter.nil? && sort_by_list.find(&slug_filter_condition)
          warn "slug_filter sort was selected, but slug_filter param is not supplied, ignoring"

          # TODO: it would be nice to have better primitives for sorting so
          # manipulation is easier than that
          params['sort_by'] = sort_by_list.reject(&slug_filter_condition).join(',')
        end
      end

      super(*args)
    end
  end
end
