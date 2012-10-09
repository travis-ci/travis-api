require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Responders
      autoload :Base,    'travis/api/app/helpers/responders/base'
      autoload :Image,   'travis/api/app/helpers/responders/image'
      autoload :Json,    'travis/api/app/helpers/responders/json'
      autoload :Service, 'travis/api/app/helpers/responders/service'
      autoload :Xml,     'travis/api/app/helpers/responders/xml'
    end
  end
end
