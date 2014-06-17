require 'travis/api/app'
require 'travis/yaml'

class Travis::Api::App
  class Endpoint
    class Lint < Endpoint
      def lint
        request.body.rewind
        content  = params[:content] || request.body.read
        parsed   = Travis::Yaml.parse(content)
        warnings = parsed.nested_warnings.map { |k, m| { key: k, message: m } }
        { lint: { warnings: warnings } }.to_json
      end

      post('/', scope: :public) { lint }
      put('/',  scope: :public) { lint }
    end
  end
end
