require 'skylight'

Travis.services.send(:services).each_value do |service|
  service.send(:include, Skylight::Helpers)
  service.send(:instrument_method, :run)
end