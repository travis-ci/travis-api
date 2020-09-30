module Travis::API::V3
  class Services::BuildPermissions::FindForRepo < Service
    paginate
    result_type :build_permissions

    def run!
      result query.find_for_repo(check_login_and_find(:repository))
    end
  end
end
