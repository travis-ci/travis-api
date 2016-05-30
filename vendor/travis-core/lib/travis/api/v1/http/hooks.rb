module Travis
  module Api
    module V1
      module Http
        class Hooks
          attr_reader :repos, :options

          def initialize(repos, options = {})
            @repos = repos
            @options = options
          end

          def data
            repos.map { |repo| repo_data(repo) }
          end

          private

            def repo_data(repo)
              {
                'uid' => [repo.owner_name, repo.name].join(':'),
                'url' => "https://github.com/#{repo.owner_name}/#{repo.name}",
                'name' => repo.name,
                'owner_name' => repo.owner_name,
                'description' => repo.description,
                'active' => repo.active,
                'private' => repo.private
              }
            end
        end
      end
    end
  end
end
