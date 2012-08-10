require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Jobs < Endpoint
      # TODO: Add implementation and documentation.
      get('/') do
        if params[:ids]
          Job.where(:id => params[:ids]).includes(:commit, :log)
        else
          jobs = Job.queued.includes(:commit, :log)
          jobs = jobs.where(:queue => params[:queue]) if params[:queue]
          jobs
        end
      end

      # TODO: Add implementation and documentation.
      get('/:id') do
        body Job.find(params[:id])
      end
    end
  end
end
