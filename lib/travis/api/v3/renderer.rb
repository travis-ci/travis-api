module Travis::API::V3
  module Renderer
    EXPANDER_CACHE = Tool::ThreadLocal.new
    private_constant :EXPANDER_CACHE

    extend ConstantResolver
    extend self

    def clear(**args)
      args.select { |key, value| !value.nil? }
    end

    def href(type, script_name: nil, **args)
      expander     = EXPANDER_CACHE[[type, script_name, args.keys]] ||= begin
        resource   = Routes.resources.detect { |r| r.identifier == type }
        unprefixed = args.keys.reject { |a| a.to_s.include? ?..freeze }
        route      = resource.route
        route    &&= Mustermann.new(script_name, type: :identity) + route if script_name and not script_name.empty?
        generate_expander(route, type, unprefixed)
      end

      expander.call(args)
    end

    private

    def generate_expander(route, prefix, unprefixed)
      return proc { |**| } unless route.respond_to? :expand
      proc do |**args|
        unprefixed.each { |key| args[:"#{prefix}.#{key}"] = args.delete(key) }
        route.expand(**args)
      end
    end
  end
end
