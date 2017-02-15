module Travis::API::V3
  class Services::KeyPair::Delete < Service
    params :description, :value, prefix: :key_pair

    def run!
      com_only_service!
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).change_key!
      query.delete(repository) and deleted
    end
  end
end
