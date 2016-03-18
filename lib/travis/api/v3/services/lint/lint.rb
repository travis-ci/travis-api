require 'travis/yaml'

module Travis::API::V3
  class Services::Lint::Lint < Service
    params "content"
    def run!
      request_body.rewind
      content  = params[:content] || request_body.read
      parsed = Travis::Yaml.parse(content)
    end
  end
end
