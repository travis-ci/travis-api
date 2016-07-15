module Travis::API::V3
  class Services::Repository::Star < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      current_user = access_control.user
      query.star(current_user)
    end

    def check_access(repository)
      access_control.permissions(repository).star!
    end
  end
end
