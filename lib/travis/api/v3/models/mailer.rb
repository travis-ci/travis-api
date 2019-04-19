module Travis::API::V3::Models
  class Mailer

    def send_beta_confirmation(user)
      params = {
        user_name: user.login,
        recipients: [user.email],
        organizations: user.organizations.map(&:name)
      }

      send_email('beta_confirmation', params)
    end

    def send_email(email_type, params)
      params = params.merge(email_type: email_type)

      client.push(
        'queue' => 'email',
        'class' => 'Travis::Async::Sidekiq::Worker',
        'args'  => [nil, 'Travis::Addons::Migration::Task', 'perform', {}, params]
      )
    end

    private

    def client
      ::Sidekiq::Client
    end
  end
end
