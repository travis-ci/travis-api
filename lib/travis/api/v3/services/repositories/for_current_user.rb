module Travis::API::V3
  class Services::Repositories::ForCurrentUser < Service
    params :active, :private, :starred, :name_filter, :slug_filter,
      :managed_by_installation, :active_on_org, prefix: :repository
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      raise InstallationMissing unless Travis.config.org? || access_control.user.vcs_type != 'GithubUser' || access_control.user.installation
      result query.for_member(access_control.user)
    end
  end
end
