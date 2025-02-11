module Travis::API::V3
  class Services::Organization::Suspend < Service
    params :id, :user_ids
    result_type :bulk_change_result

    def run!
      puts "!"
      raise LoginRequired unless access_control.full_access_or_logged_in?
      puts "2, params: #{params.inspect}"
      raise WrongParams unless params.include? 'user_ids'

      res = query(:organization).suspend(true)
      puts "RES: #{res.inspect}"
      result res
    end
  end
end
