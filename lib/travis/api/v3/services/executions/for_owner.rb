module Travis::API::V3
  class Services::Executions::ForOwner < Service
    params :page, :per_page, :from, :to
    result_type :executions

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      result query(:executions).for_owner(owner, access_control.user.id, params['page'], params['per_page'],
                                          params['from'], params['to'])
    end
  end
end
