module Travis::API::V3
  module Services
    def self.[](key)
      return key if key.respond_to? :new
      const_get(key.to_s.camelize)
    end
  end
end
