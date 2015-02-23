module Travis::API::V3
  module Renderer
    EXPANDER_CACHE = Tool::ThreadLocal.new
    private_constant :EXPANDER_CACHE

    extend ConstantResolver
    extend self

    def clear(**args)
      args.select { |key, value| !value.nil? }
    end

    def href(type, string_args = nil, script_name: nil, **args)
      args.merge! string_args if string_args

      expander      = EXPANDER_CACHE[[type, script_name, args.keys]] ||= begin
        resource    = Routes.resources.detect { |r| r.identifier == type }
        route       = resource.route
        route     &&= Mustermann.new(script_name, type: :identity) + route if script_name and not script_name.empty?
        key_mapping = {}
        args.keys.each do |key|
          case key.to_s
          when /\./        then key_mapping[key.to_sym]        = key unless key.is_a? Symbol
          when /^(.+)_id$/ then key_mapping[:"#{$1}.id"]       = key
          else                  key_mapping[:"#{type}.#{key}"] = key
          end
        end
        generate_expander(route, key_mapping)
      end

      expander.call(args)
    end

    private

    def generate_expander(route, key_mapping)
      return proc { |**| } unless route.respond_to? :expand
      proc do |args|
        key_mapping.each { |a, b| args[a] = args.delete(b) }
        route.expand(:ignore, **args)
      end
    end
  end
end
