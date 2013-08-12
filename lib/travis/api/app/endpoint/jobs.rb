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
        resource = service(:find_log, params).run
        if !resource || resource.archived?
          archived_log_path = archive_url("/jobs/#{params[:job_id]}/log.txt")

          if params[:cors_hax]
            status 204
            headers['Access-Control-Expose-Headers'] = 'Location'
            headers['Location'] = archived_log_path
          else
            redirect archived_log_path, 307
          end
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

    post '/:id/cancel' do
      service = self.service(:cancel_job, params)
      if !service.authorized?
        json = { error: {
          message: "You don't have access to cancel job(#{params[:id]})"
        } }
        status 403
        respond_with json
      elsif !service.can_cancel?
        json = { error: {
          message: "The job(#{params[:id]}) can't be canceled",
          code: 'cant_cancel'
        } }
        status 422
        respond_with json
      else
        service.run
        status 204
      end
    end
  end
end
