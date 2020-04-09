module Travis
  module Providers
    class Github < Base
      BASE_URL = Travis::Config.load.providers.github.base_url

      def profile_link
        "#{BASE_URL}#{profile.login}"
      end

      def repo_link
        "#{BASE_URL}#{profile.slug}"
      end

      def manage_repo_link
        "#{BASE_URL}apps/travis-ci/installations/new/permissions?suggested_target_id=#{profile.vcs_id}"
      end
    end
  end
end
