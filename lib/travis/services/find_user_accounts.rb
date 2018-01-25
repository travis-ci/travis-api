require 'travis/services/base'

module Travis
  module Services
    class FindUserAccounts < Base
      register :find_user_accounts

      def run
        user_account = ::Account.from(current_user, :repos_count => repos_count_for_user[current_user.id])
        org_accounts = orgs.map do |record|
          ::Account.from(record, :repos_count => repos_counts_for_orgs[record.id])
        end

        [user_account] + org_accounts
      end

      private

        def orgs
          Organization.where(id: org_ids)
        end

        def repos_counts_for_orgs
          @repos_counts_for_orgs ||= Repository.counts_by_owner_ids(org_ids, 'Organization')
        end

        def repos_count_for_user
          @repo_count_for_user ||= Repository.counts_by_owner_ids([current_user.id], 'User')
        end

        def org_ids
          repos = current_user.repositories
          unless params[:all]
            repos = repos.administrable
          end
          repos
            .select('DISTINCT owner_id')
            .where("owner_type = 'Organization'")
            .map(&:owner_id)
        end
    end
  end
end
