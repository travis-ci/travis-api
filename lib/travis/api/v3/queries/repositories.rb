module Travis::API::V3
  class Queries::Repositories < Query
    params :active, :private, prefix: :repository

    def for_member(user)
      all.joins(:users).where(users: user_condition(user), invalidated_at: nil)
    end

    def for_owner(owner)
      filter(owner.repositories)
    end

    def all
      @all ||= filter(Models::Repository)
    end

    def filter(list)
      list = list.where(invalidated_at: nil)
      list = list.where(active:  bool(active))  unless active.nil?
      list = list.where(private: bool(private)) unless private.nil?
      list = list.includes(:owner) if includes? 'repository.owner'.freeze

      if includes? 'repository.last_build'.freeze or includes? 'build'.freeze
        list = list.includes(:last_build)
        list = list.includes(last_build: :commit) if includes? 'build.commit'.freeze
      end

      list = list.includes(default_branch: :last_build)
      list = list.includes(default_branch: { last_build: :commit }) if includes? 'build.commit'.freeze
      list
    end
  end
end
