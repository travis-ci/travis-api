module Travis::API::V3
  class Services::Organization::Suspend < Service
    params :id, :user_ids
    result_type :bulk_change_result

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      raise WrongParams unless params.include? 'user_ids'

      result query(:organization).suspend(true)
    end
  end
end
