module Travis::API::V3
  class Services::Repository::Star < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      return repo_migrated if migrated?(repository)

      current_user = access_control.user
      result query.star(current_user)
    end

    def check_access(repository)
      access_control.permissions(repository).star!
    end
  end
end
