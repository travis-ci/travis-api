module Travis::API::V3
  class Services::CustomImages::ForOwner < Service
    result_type :custom_images

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      repo = owner.repositories.first
      raise InsufficientAccess unless repo
      access_control.permissions(repo).build_create!

      results = query(:custom_images).for_owner(owner)
      result results
    end
  end
end
