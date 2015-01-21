require 'conditional_skylight'

if ConditionalSkylight.enabled?
  Travis.services.send(:services).each_value do |service|
    service.send(:include, ConditionalSkylight::Mixin)
    service.send(:instrument_method, :run)
  end
end