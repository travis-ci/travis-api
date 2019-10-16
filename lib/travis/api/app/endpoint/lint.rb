require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Lint < Endpoint
      WARNING = /\[(alert|error|warn)\]/

      post('/', scope: :public) { lint }
      put('/',  scope: :public) { lint }

      def lint
        request.body.rewind
        content = params[:content] || request.body.read
        query = Travis::API::V3::Queries::Lint.new({}, :lint)
        msgs = query.lint(content)
        { lint: { warnings: warnings(msgs) } }.to_json
      end

      def warnings(msgs)
        msgs = msgs.select { |msg| WARNING =~ msg }
        msgs.map { |msg| { key: [], message: msg } }
      end
    end
  end
end
