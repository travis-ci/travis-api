module Travis::API::V3
  class Queries::UserSettings < Query
    FEATURE_FLAGGED = %i(
      auto_cancel_pushes
      auto_cancel_pull_requests
    )

    def find(repo)
      filter(repo, repo.user_settings)
    end

    private

      def filter(repo, settings)
        settings.select { |setting| !flagged?(setting) || active?(repo) }
      end

      def flagged?(setting)
        FEATURE_FLAGGED.include?(setting.name)
      end

      def active?(repo)
        Travis::Features.owner_active?(:auto_cancel, repo.owner)
      end
  end
end
