module Travis::API::V3
  class Services::CustomImages::ForOwner < Service
    result_type :custom_images

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner

      if owner.is_a?(Travis::API::V3::Models::User)
        raise InsufficientAccess unless access_control.user.id == owner.id
      else
        membership = Models::Membership.where(organization_id: owner.id).joins(:user).includes(:user).first
        raise NotFound unless membership

        build_permission = membership.build_permission.nil? ? true : membership.build_permission
        raise InsufficientAccess unless build_permission
      end

      results = query(:custom_images).for_owner(owner)
      result results
    end
  end
end
