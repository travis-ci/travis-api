module Travis::API::V3
  class Services::Users::Suspend < Service
    params :user_ids
    result_type :bulk_change_result

    def run!
      puts "PARAMS: #{params.inspect}"
      raise LoginRequired unless access_control.class.name == 'Travis::API::V3::AccessControl::Internal'
      puts "WP"
      raise WrongParams unless params.include? 'user_ids'

      result query(:users).suspend(true)
    end
  end
end
