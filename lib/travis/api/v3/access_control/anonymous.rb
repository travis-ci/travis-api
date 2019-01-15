require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::Anonymous < AccessControl::Generic
    def self.new
      @instance ||= super
    end

    # use when Authorization header is not set
    auth_type(nil)

    def self.for_request(*)
      new
    end

    def admin_for(repository)
      raise LoginRequired
    end

    private

    def visible_objects(list, repository_id, factory)
      return factory.none unless unrestricted_api?
      list.where(private: false)
    end
  end
end
