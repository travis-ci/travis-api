module Travis::API::V3
  class Services::KeyPair::Delete < Service
    params :description, :value, prefix: :key_pair

    def run!
      repository = check_login_and_find(:repository)
      private_repo_feature!(repository)
      key_pair = find(:key_pair, repository)
      access_control.permissions(repository).delete_key_pair!
      query.delete(repository) and deleted
    end
  end
end
