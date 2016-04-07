module Travis::API::V3
  class Services::Tmate::Event < Service
    # Documentation of the tmate webhooks:
    # https://github.com/tmate-io/tmate/wiki/Webhooks

    params :type, :entity_id, :userdata, :params

    attr_reader :job

    def run
      raise WrongParams unless token = params['userdata']
      raise NotFound    unless job_id = Travis::API::V3::TmateStore.find_job_id(token)
      raise NotFound    unless @job = Models::Job.find_by_id(job_id)

      case params['type']
      when 'session_register', 'session_open' then on_session_open(params['params'])
      when 'session_close' then on_session_close(params['params'])
      end

      accepted
    end

    def on_session_open(event_params)
      session_data = event_params.symbolize_keys.slice(:stoken, :stoken_ro, :ssh_cmd_fmt)
      job.debug_options = job.debug_options.merge(:session_state => 'opened',
                                                  :session_data  => session_data)

      job.save!
    end

    def on_session_close(event_params)
      job.debug_options = job.debug_options.merge(:session_state => 'closed',
                                                  :session_data  => {})
      job.save!
    end
  end
end
