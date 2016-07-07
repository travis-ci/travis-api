module Travis::API::V3
  class Services::Repository::Unstar < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      current_user = access_control.user
      query.unstar(current_user)
    end

    def check_access(repository)
      access_control.permissions(repository).unstar!
    end
  end
end
