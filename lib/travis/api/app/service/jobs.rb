module Travis
  module Api
    class App
      class Service
        class Jobs < Service
          def collection
            if params[:ids]
              Job::Test.where(:id => params[:ids]).includes(:commit, :log)
            else
              jobs = Job::Test.queued.includes(:commit, :log)
              jobs = jobs.where(:queue => params[:queue]) if params[:queue]
              jobs
            end
          end

          def item
            Job::Test.find(params[:id])
          end
        end
      end
    end
  end
end
