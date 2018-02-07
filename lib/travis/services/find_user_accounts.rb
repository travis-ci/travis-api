require 'travis/services/base'

module Travis
  module Services
    class FindUserAccounts < Base
      register :find_user_accounts

      def run
        [user_account] + organizations_accounts
      end

      private

        def owners_with_counts
          @owners_with_counts ||= begin
            permissions_query = 'SELECT repository_id FROM permissions WHERE user_id = ?'
            unless params[:all]
              permissions_query << " AND permissions.admin = 't'"
            end

            query = <<-QUERY
              SELECT owner_id, owner_type, count(id) AS repos_count
              FROM repositories
              WHERE id in (#{permissions_query})
                AND (owner_type = 'Organization' OR (owner_type = 'User' AND owner_id = ?))
                AND invalidated_at IS NULL
              GROUP BY owner_id, owner_type;
            QUERY
            Repository.find_by_sql([query, current_user.id, current_user.id])
          end
        end

        def organizations_accounts
          orgs = owners_with_counts
            .find_all { |r| r['owner_type'] == 'Organization' }

          ids = orgs.map { |r| r['owner_id'] }
          counts = Hash[*orgs.map { |o| [o['owner_id'].to_i, o['repos_count'].to_i] }.flatten]
          Organization.find(ids).map { |org|
            ::Account.from(org, repos_count: counts[org.id])
          }
        end

        def user_account
          user = owners_with_counts.detect { |r|
            r['owner_type'] == 'User' && r['owner_id'].to_i == current_user.id
          }

          ::Account.from(current_user, repos_count: user ? user['repos_count'] : 0)
        end
    end
  end
end
