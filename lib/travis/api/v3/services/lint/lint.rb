module Travis::API::V3
  class Services::Lint::Lint < Service
    def run
      request.body.rewind
      content  = params[:content] || request.body.read
      parsed   = Travis::Yaml.parse(content)
      warnings = parsed.nested_warnings.map { |k, m| { key: k, message: m } }
      payload = { lint: { warnings: warnings } }.to_json
      payload
    end
  end
end
