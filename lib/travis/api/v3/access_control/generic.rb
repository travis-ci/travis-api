module Travis::API::V3
  class AccessControl::Generic
    DEFAULT_LIMIT = 25
    MAX_LIMT      = 100
    NO_LIMIT      = 2 ** 62 - 1 # larges Fixnum on MRI

    def self.for_request(type, payload, env)
    end

    def self.auth_type(*list)
      list.each { |e| (AccessControl::REGISTER[e] ||= []) << self }
    end

    def visible?(object)
      full_access? or dispatch(object)
    end

    def user
    end

    def logged_in?
      false
    end

    # def limit(resource_type, value = nil)
   #    case value
   #    when ''.freeze, 'true'.freeze, true, nil then DEFAULT_LIMIT
   #    when 'false'.freeze, false               then NO_LIMIT
   #    when /^\d+$/                             then limit(resource_type, Integer(value))
   #    when 0..MAX_LIMIT                        then value
   #    end
   #    # # TODO move to config
   #    # value = Time.now.to_i   if value == false or value == 'false'.freeze
   #    # value = 25              if value.nil? or value == ''.freezee or value ==
   #    # value = Integer(value)
   #    # value = 100             if value > 100 and not full_access?
   #    # value = 0               if value < 0
   #  rescue TypeError
   #    raise WrongParams, 'limit must be a positive integer'.freeze, resource_type: resource_type
   #  end

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

    def public_api?
      !Travis.config.private_api
    end

    def unrestricted_api?
      full_access? or logged_in? or public_api?
    end

    private

    def dispatch(object, method = caller_locations.first.base_label)
      method = object.class.name.underscore + ?_.freeze + method
      send(method, object) if respond_to?(method, true)
    end
  end
end
