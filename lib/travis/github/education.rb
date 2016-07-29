require 'timeout'
require 'json'

module Travis
  module Github
    class Education < Struct.new(:github_oauth_token)
      def self.active?(owner)
        if Travis::Features.feature_active?(:education) || Travis::Features.owner_active?(:education, owner)
          owner.education? if owner.respond_to? :education?
        end
      end

      def self.education_queue?(owner)
        # this method is here so it can be overridden with subscription logic
        active?(owner)
      end

      include Travis::Logging

      def student?
        data['student']
      end

      def data
        @data ||= fetch
      end

      def fetch
        Timeout::timeout(timeout) do
          remote = GH::Remote.new
          remote.setup('https://education.github.com/api', token: github_oauth_token)
          response = remote.fetch_resource('/user')
          JSON.parse(response.body)
        end
      rescue GH::Error, JSON::ParserError, Timeout::Error => e
        log_exception(e) unless e.is_a? GH::Error and e.info[:response_status] == 401
        {}
      end

      def timeout
        Travis.config.education_endpoint_timeout || 2
      end
    end
  end
end
