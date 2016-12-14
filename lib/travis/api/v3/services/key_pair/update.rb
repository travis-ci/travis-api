module Travis::API::V3
  class Services::KeyPair::Update < Service
    params :description, :value, prefix: :key_pair

    def run!
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).change_key!
      key_pair = query.update(repository)
      result(:key_pair, key_pair, status: 200)
    end
  end
end
