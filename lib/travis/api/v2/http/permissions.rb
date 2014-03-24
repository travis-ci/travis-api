module Travis
  module Api
    module V2
      module Http
        class Permissions
          attr_reader :permissions, :options

          def initialize(permissions, options = {})
            @permissions = permissions
            @options = options
          end

          def data
            {
              'permissions' => repo_ids,
              'admin'       => admin_ids,
              'pull'        => pull_ids,
              'push'        => push_ids
            }
          end

          private
            def filtered_ids(perm = nil)
              if perm
                permissions.find_all { |p| p.send("#{perm}?") }.map { |permission| permission.repository_id }
              else
                permissions.map { |permission| permission.repository_id }
              end
            end

            def repo_ids
              filtered_ids
            end

            def admin_ids
              filtered_ids(:admin)
            end

            def pull_ids
              filtered_ids(:pull)
            end

            def push_ids
              filtered_ids(:push)
            end
        end
      end
    end
  end
end
