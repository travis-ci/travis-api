module Travis::API::V3
  class Services::SslKey::Create < Service
    def run!
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).create_key_pair!
      ssl_key = query.regenerate(repository)
      result(:ssl_key, ssl_key, status: 201)
    end
  end
end
