module Travis
  module Github
    module Services
      class FindOrCreateRepo < Travis::Services::Base
        register :github_find_or_create_repo

        def run
          repo = find || create
          repo.update_attributes(params)
          repo
        end

        private

          def find
            unless params[:github_id]
              message = "No github_id passed to FindOrCreateRepo#find, params: #{params.inspect}"
              ActiveSupport::Deprecation.warn(message)
              Travis.logger.info(message)
            end

            query = if params[:github_id]
              { github_id: params[:github_id] }
            else
              { owner_name: params[:owner_name], name: params[:name] }
            end

            run_service(:find_repo, query)
          end

          def create
            unless params[:github_id]
              message = "No github_id passed to FindOrCreateRepo#find, params: #{params.inspect}"
              ActiveSupport::Deprecation.warn(message)
              Travis.logger.info(message)
            end
            Repository.create!(:owner_name => params[:owner_name], :name => params[:name], github_id: params[:github_id])
          rescue ActiveRecord::RecordNotUnique
            find
          end
      end
    end
  end
end
