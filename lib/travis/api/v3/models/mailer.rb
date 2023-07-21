module Travis::API::V3::Models
  class Mailer

    def send_beta_confirmation(user)
      params = {
        user_name: user.login,
        recipients: [user.email],
        organizations: user.organizations.map(&:name)
      }

      send_email('Travis::Addons::Migration::Task', 'beta_confirmation', params)
    end

    def send_email(task_class, email_type, params)
      params = params.merge(email_type: email_type)

      client.push(
        'queue' => 'email',
        'class' => 'Travis::Async::Sidekiq::Worker',
        'args'  => [nil, task_class, 'perform', {}, params].map! {|arg| arg.to_json}
      )
    end

    private

    def client
      ::Sidekiq::Client
    end
  end
end
