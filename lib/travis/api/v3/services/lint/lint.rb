require 'travis/yaml'

module Travis::API::V3
  class Services::Lint::Lint < Service
    params 'content'
    def run!
      request_body.rewind
      content  = params['content'.freeze] || request_body.read
      Travis::Yaml.parse(content)
    end
  end
end
