module Travis::API::V3
  class Services::Repository::Star < Service
    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      check_access(repository)
      current_user = access_control.user
      query.star(current_user)
    end

    def check_access(repository)
      access_control.permissions(repository).star!
    end
  end
end
