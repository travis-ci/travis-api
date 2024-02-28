
# frozen_string_literal: true

module Travis::API::V3
  class ScannerClient
    class ConfigurationError < StandardError; end

    def initialize(repository_id)
      @repository_id = repository_id
    end

    def scan_results(page, limit)
      query_string = query_string_from_params(
        repository_id: @repository_id,
        limit: limit,
        page: page || '1',
      )
      response = connection.get("/scan_results?#{query_string}")

      handle_errors_and_respond(response) do |body|
        scan_results = body['scan_results'].map do |scan_result|
          Travis::API::V3::Models::ScanResult.new(scan_result)
        end

        Travis::API::V3::Models::ScannerCollection.new(scan_results, body.fetch('total_count', 0))
      end
    end

    def get_scan_result(id)
      response = connection.get("/scan_results/#{id}")
      handle_errors_and_respond(response) do |body|
        Travis::API::V3::Models::ScanResult.new(body.fetch('scan_result'))
      end
    end

    private

    def handle_errors_and_respond(response)

      body = response&.body&.length > 0 && response.body.is_a?(String)  ? JSON.parse(response.body) : response.body
      case response.status
      when 200, 201
        yield(body) if block_given?
      when 202
        true
      when 204
        true
      when 400
        raise Travis::API::V3::ClientError, body&.fetch('error', '')
      when 403
        raise Travis::API::V3::InsufficientAccess, body&.fetch('rejection_code', '')
      when 404
        raise Travis::API::V3::NotFound, body&.fetch('error', '')
      when 422
        raise Travis::API::V3::UnprocessableEntity, body&.fetch('error', '')
      else
        raise Travis::API::V3::ServerError, 'Scanner API failed'
      end
    end

    def connection(timeout: 20)
      @connection ||= Faraday.new(url: scanner_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.headers[:Authorization] = "Token token=\"#{scanner_token}\""
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.options[:open_timeout] = timeout
        conn.options[:timeout] = timeout
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        conn.adapter :net_http
      end
    end

    def scanner_url
      Travis.config.scanner.url || raise(ConfigurationError, 'No Scanner API URL configured!')
    end

    def scanner_token
      Travis.config.scanner.token || raise(ConfigurationError, 'No Scanner Auth Token configured!')
    end

    def query_string_from_params(params)
      params.delete_if { |_, v| v.nil? || v.empty? }.to_query
    end
  end
end
