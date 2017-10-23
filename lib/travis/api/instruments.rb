require 'conditional_skylight'
require 'conditional_appsignal'

if ConditionalSkylight.enabled?
  Travis.services.send(:services).each_value do |service|
    service.send(:include, ConditionalSkylight::Mixin)
    service.send(:instrument_method, :run)
  end
end

if ConditionalAppsignal.enabled?
  Travis.services.send(:services).each_value do |service|
    service.send(:include, ConditionalAppsignal::Mixin)
    service.send(:instrument_method, :run)
  end
end
