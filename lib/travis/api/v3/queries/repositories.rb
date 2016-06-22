module Travis::API::V3
  class Queries::Repositories < Query
    params :active, :private, :starred, prefix: :repository
    sortable_by :id, :github_id, :owner_name, :name, active: sort_condition(:active),
                :'default_branch.last_build' => 'builds.started_at',
                :current_build => "repositories.current_build_id %{order} NULLS LAST"

    # this is a hack for a bug in AR that generates invalid query when it tries
    # to include `current_build` and join it at the same time. We don't actually
    # need the join, but it will be automatically added, because `current_build`
    # is an association. This prevents adding the join. We will probably be able
    # to remove it once we move to newer AR versions
    prevent_sortable_join :current_build

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

      list = list.includes(default_branch: :last_build)
      list = list.includes(:current_build)
      list = list.includes(default_branch: { last_build: :commit }) if includes? 'build.commit'.freeze
      sort list
    end
  end
end
