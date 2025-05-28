module Travis::API::V3
  class Services::CustomImages::Delete < Service
    params :image_ids

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      owner = query(:owner).find
      raise NotFound unless owner

      if owner.is_a?(Travis::API::V3::Models::User)
        access_control.permissions(owner).write!
      else
        access_control.permissions(owner).admin!
      end

      query.delete(params['image_ids'], owner, access_control.user)
      deleted
    end
  end
end
