require 'faraday'

module Travis::API::V3::Models
  class Import
    class ImportDisabledError < StandardError; end
    class ImportRequestFailed < StandardError; end
    attr_accessor :owner, :current_user

    def initialize(owner, current_user)
      self.owner = owner
      self.current_user = current_user
    end

    def import!
      if !Travis::Features.owner_active?(:import_owner, owner)
        raise ImportDisabledError
      end

      token = Travis.config.merge.auth_token
      url   = Travis.config.merge.api_url
      connection = Faraday.new(url: url) do |c|
        c.request :json
        c.use Faraday::Request::Authorization, 'Token', token
        c.use OpenCensus::Trace::Integrations::FaradayMiddleware
        c.adapter Faraday.default_adapter
      end
      response = connection.put("/api/#{type}/#{owner.id}") do |request|
        request.body = { user_id: current_user.id }
      end

      unless response.success?
        raise ImportRequestFailed
      end
    end

    def type
      case owner
      when User         then :user
      when Organization then :org
      end
    end
  end
end
