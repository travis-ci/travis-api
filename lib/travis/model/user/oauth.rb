class User
  module Oauth
    class << self
      def find_or_create_by(payload)
        attrs = attributes_from(payload)
        user = User.find_by_github_id(attrs['github_id'])
        user ? user.update(attrs) : user = User.create!(attrs)
        user
      end

      def attributes_from(payload)
        {
          'name'               => payload['info']['name'],
          'email'              => payload['info']['email'],
          'login'              => payload['info']['nickname'],
          'github_id'          => payload['uid'].to_i,
          'github_oauth_token' => payload['credentials']['token'],
          'gravatar_id'        => payload['extra']['raw_info']['gravatar_id']
        }
      end
    end
  end
end
