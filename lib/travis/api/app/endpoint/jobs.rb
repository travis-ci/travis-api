require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Jobs < Endpoint
      get '/' do
        respond_with service(:find_jobs, params)
      end

      get '/:id' do
        respond_with service(:find_job, params)
      end

      get '/:job_id/log' do
        resource = service(:find_artifact, params).run
        if !resource || resource.archived?
          redirect archive_url("/jobs/#{params[:job_id]}/log.txt"), 307
        else
          respond_with resource
        end
      end

      def archive_url(path)
        "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
      end

      def hostname(name)
        "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
      end
    end
  end
end
