if ENV['SKYLIGHT_AUTHENTICATION']
  require_relative 'skylight/actual'
else
  require_relative 'skylight/dummy'
end
