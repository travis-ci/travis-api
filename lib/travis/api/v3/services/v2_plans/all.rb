module Travis::API::V3
  class Services::V2Plans::All < Service
    params :organization_id
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      begin
        unless Travis::API::V3::Authorizer::new(access_control.user.id).for_org(params['organization_id'], 'account_plan_view')
          raise InsufficientAccess
        end
      rescue AuthorizerError
        #nop
      end if !Travis.config.legacy_roles && params.include?('organization_id')

      result query(:v2_plans).all(access_control.user.id)
    end
  end
end
