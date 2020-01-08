require 'travis/api/v3/access_control/generic'
require 'travis/api/app/access_token'
require 'digest/sha1'
require 'openssl'

module Travis::API::V3
  # Support signed requests to not expose the secret to an untrusted environment.
  class AccessControl::Signature < AccessControl::Generic
    auth_type('signature')

    def self.for_request(type, payload, env)
      *args, signature = payload
      options          = Hash[args.map { |a| a.split(?=.freeze, 2) }]
      challenge        = ""



      if vcs_id = options[?u.freeze]
        return unless user = ::User.find_by(vcs_id: vcs_id) || ::User.find_by(github_id: vcs_id)
      end

      if application = options[?a.freeze]
        return unless Travis.config.applications and app_config = Travis.config.applications[application]
      end

      if c = options[?c.freeze]
        challenge << env['REQUEST_METHOD'.freeze] << "\n".freeze                     if c.include?(?m.freeze)
        challenge << env['SCRIPT_NAME'.freeze]    << env['PATH_INFO'.freeze] << "\n" if c.include?(?p.freeze)
      end

      challenge << app_config[:secret] if app_config and user
      challenge << args.join(?:.freeze)

      if app_config
        control = AccessControl::Application.new(application, user: user)
        secrets = user ? secrets_for(user) : [app_config[:secret]]
      else
        control = AccessControl::User.new(user)
        secrets = secrets_for(user)
      end

      if scope = options[?s.freeze]
        control &&= AccessControl::Scoped.new(scope, control)
      end

      control if secrets.any? { |secret| signed(challenge, secret) == signature }
    end

    def self.secrets_for(user)
      [
        Travis::Api::App::AccessToken.new(user: user, app_id: 1), # generated from github token
        Travis::Api::App::AccessToken.new(user: user, app_id: 0)  # used by web
      ]
    end

    def self.signed(challenge, secret)
      OpenSSL::HMAC.hexdigest('sha256'.freeze, secret, challenge)
    end
  end
end
