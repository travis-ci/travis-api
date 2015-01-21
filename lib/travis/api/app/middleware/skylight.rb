require 'conditional_skylight'

if ConditionalSkylight.enabled?
  require_relative 'skylight/actual'
else
  require_relative 'skylight/dummy'
end
