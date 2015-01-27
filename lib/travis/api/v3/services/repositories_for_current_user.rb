module Travis::API::V3
  class Services::RepositoriesForCurrentUser < Service
    def run
      raise LoginRequired           unless access_control.logged_in?
      raise NotFound, :repositories unless access_control.user
      repositories = ::Repository::joins(:users).where(users: { id: access_control.user.id })
      Result.new(:repositories, repositories)
    end
  end
end
