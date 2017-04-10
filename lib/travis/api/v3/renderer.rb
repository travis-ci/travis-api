module Travis::API::V3
  module Renderer
    PRIMITIVE = [String, Symbol, Numeric, true, false, nil]
    private_constant :PRIMITIVE

    EXPANDER_CACHE = Tool::ThreadLocal.new
    private_constant :EXPANDER_CACHE

    extend ConstantResolver
    extend self

    def clear(**args)
      args.compact
    end

    def href(type, string_args = nil, script_name: nil, **args)
      args.merge! string_args if string_args

      expander      = EXPANDER_CACHE[[type, script_name, args.keys]] ||= begin
        resource    = Routes.resources.detect { |r| r.identifier == type }
        verb, sub   = resource.services.key(:find)                         if resource
        route       = resource.route                                       if verb
        route      += sub                                                  if sub
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

    def render_model(model, type: model.class.name[/[^:]+$/].to_sym, mode: nil, **options)
      Renderer[type].render(model, mode || :minimal, **options)
    end

    def render_value(value, **options)
      case value
      when Hash                   then value.map { |k, v| [k, render_value(v, **options)] }.to_h
      when Array                  then value.map { |v   | render_value(v, **options)      }
      when *PRIMITIVE             then value
      when Time, DateTime         then value.strftime('%Y-%m-%dT%H:%M:%SZ')
      when Model                  then render_model(value, **options)
      when ActiveRecord::Relation then render_value(value.to_a, **options)
      when ActiveRecord::Associations::CollectionProxy then render_value(value.to_a, **options)
      when Travis::Settings::EncryptedValue then value.decrypt
      when Travis::RemoteLogPart, Travis::RemoteLog then render_value(value.as_json, **options)
      else raise ArgumentError, 'cannot render %p (%p)' % [value.class, value]
      end
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
