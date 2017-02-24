module Travis::API::V3
  class Services::KeyPair::Update < Service
    params :description, :value, prefix: :key_pair

    def run!
      repository = check_login_and_find(:repository)
      key_pair = find(:key_pair, repository)
      access_control.permissions(key_pair).write!
      key_pair = query.update(key_pair)
      result(:key_pair, key_pair, status: 200)
    end
  end
end
