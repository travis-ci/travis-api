require 'travis/services/base'

module Travis
  module Services
    class FindUserAccounts < Base
      register :find_user_accounts

      def run
        ([current_user] + orgs).map do |record|
          ::Account.from(record, :repos_count => repos_counts[record.id])
        end
      end

      private

        def orgs
          Organization.where(id: account_ids)
        end

        def repos_counts
          @repos_counts ||= Repository.counts_by_owner_ids(account_ids)
        end

        def account_ids
          repos = current_user.repositories
          unless params[:all]
            repos = repos.administrable
          end
          org_ids = repos
                      .select('DISTINCT owner_id')
                      .where("owner_type = 'Organization'")
                      .map(&:owner_id)

          [current_user.id] + org_ids
        end
    end
  end
end
