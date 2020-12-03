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
    end
  end
end
