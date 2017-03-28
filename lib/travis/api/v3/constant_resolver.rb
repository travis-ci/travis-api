require 'tool/thread_local'

module Travis::API::V3
  module ConstantResolver
    def self.extended(base)
      base.resolver_cache = Tool::ThreadLocal.new
      super
    end

    attr_accessor :resolver_cache

    def [](key, raise_unknown = true)
      return key unless key.is_a? Symbol
      resolver_cache[key] ||= Travis::API::V3::Permissions::Job if key == :"travis/remote_log"
      resolver_cache[key] ||= const_get(key.to_s.camelize, false)
    rescue NameError => e
      raise e if raise_unknown
      raise e unless e.message.include?(key.to_s.camelize)
    end

    def extended(base)
      base.extend(ConstantResolver)
      super
    end
  end
end
