module Travis::API::V3
  class Services::Broadcasts::ForCurrentUser < Service
    def run!
      query.for_user(find(:user))
    end
  end
end
