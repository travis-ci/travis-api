require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::Anonymous < AccessControl::Generic
    # use when Authorization header is not set
    auth_type(nil)

    def self.for_request(*)
      new
    end
  end
end
