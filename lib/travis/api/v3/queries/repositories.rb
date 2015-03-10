module Travis::API::V3
  class Queries::Repositories < Query
    params :active, :private, prefix: :repository

    def for_member(user)
      all.joins(:users).where(users: user_condition(user))
    end

    def all
      @all ||= begin
        all = Models::Repository
        all = all.where(active:  bool(active))  unless active.nil?
        all = all.where(private: bool(private)) unless private.nil?
        all = all.includes(:owner)       if includes? 'repository.owner'.freeze
        all = all.includes(:last_build)  if includes? 'repository.last_build'.freeze
        all = all.includes(:default_branch)
        all
      end
    end
  end
end
