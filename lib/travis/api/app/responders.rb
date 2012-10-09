require 'travis/api/app'

class Travis::Api::App
  module Responders
    autoload :Base,    'travis/api/app/responders/base'
    autoload :Image,   'travis/api/app/responders/image'
    autoload :Json,    'travis/api/app/responders/json'
    autoload :Service, 'travis/api/app/responders/service'
    autoload :Xml,     'travis/api/app/responders/xml'
  end
end
