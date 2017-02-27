require 'customerio'

module Travis
  class Customerio
    include Sidekiq::Worker

    sidekiq_options queue: 'customerio'

    def self.update(user)
      return unless Travis.config.customerio.site_id

      perform_async(user.id)
    end

    def perform(user_id)
      return unless Travis.config.customerio.site_id

      user = User.find(user_id)

      # send event to customer.io
      payload = {
        :id => user.id,
        :name => user.name,
        :login => user.login,
        :email => primary_email_for_user(user),
        :created_at => user.created_at.to_i,
        :github_id => user.github_id,
        :education => user.education,
        :first_logged_in_at => user.first_logged_in_at.to_i,
        :travis_domain => Travis.config.client_domain
      }

      client.identify(payload)
    rescue StandardError => e
      Travis.logger.error "Could not update Customer.io for User: #{user.id}:#{user.login} with message:#{e.message}"
    end

    private
    def client
      @client ||= ::Customerio::Client.new(Travis.config.customerio.site_id, Travis.config.customerio.api_key, :json => true)
    end

    def primary_email_for_user(user)
      oauth_token = user.github_oauth_token
      # check for the users primary email address (we don't store this info)
      GH.with(token: oauth_token, client_id: nil) { GH['user/emails'] }.select { |e| e['primary'] }.first['email']
    end
  end
end
