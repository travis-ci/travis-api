module Travis::API::V3
  class Services::RepositoriesForCurrentUser < Service
    def run
      raise LoginRequired           unless access_control.logged_in?
      raise NotFound, :repositories unless access_control.user
      repositories = query(:repositories).for_member(access_control.user)
      Result.new(:repositories, repositories)
    end
  end
end
