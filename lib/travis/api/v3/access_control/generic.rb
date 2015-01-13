module Travis::API::V3
  class AccessControl::Generic
    def self.for_request(type, payload, env)
    end

    def self.auth_type(*list)
      list.each { |e| (AccessControl::REGISTER[e] ||= []) << self }
    end

    def visible?(object)
      full_access? or dispatch(object)
    end

    protected

    def repository_visible?(repository)
      return true if unrestricted_api? and not repository.private?
      private_repository_visible?(repository)
    end

    def private_repository_visible?(repository)
      false
    end

    def full_access?
      false
    end

    def logged_in?
      false
    end

    def public_api?
      Travis.config.public_api
    end

    def unrestricted_api?
      full_access? or logged_in? or public_api?
    end

    private

    def dispatch(object, method = caller_locations.first.base_label)
      method = object.class.name.underscore + ?_.freeze + method
      public_send(method) if respond_to?(method)
    end
  end
end
