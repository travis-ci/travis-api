module Travis::API::V3
  class Services::Repositories::ForCurrentUser < Service
    params :active, :private, :starred, :slug_filter, prefix: :repository
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      result query.for_member(access_control.user)
    end
  end
end
