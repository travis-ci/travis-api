# frozen_string_literal: true

module Travis::API::V3
  class ArtifactsClient
    class ConfigurationError < StandardError; end

    def initialize(user_id)
      @user_id = user_id
    end

    def create_config(config, image_name = nil)
      response = connection.post("/api/config/create", config: config, imageName: image_name)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def update_config(config, image_name = nil)
      response = connection.post("/api/config/update", config: config, imageName: image_name)

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def image_logs(image_name)
      response = connection.get("/api/#{image_name}/logs")

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def image_info(image_name)
      response = connection.get("/api/#{image_name}/info")

      handle_errors_and_respond(response) do |body|
        body
      end
    end

    def delete_image(image_name)
      response = connection.delete("/api/#{image_name}", config: config, imageName: image_name)

      handle_errors_and_respond(response)
    end

    private

    def handle_errors_and_respond(response)
      case response.status
      when 200, 201
        yield(response.body.transform_keys { |key| key.to_s.underscore }) if block_given?
      when 202
        true
      when 204
        true
      when 400
        raise Travis::API::V3::ClientError, response.body.fetch('errors', response.body.fetch('Errors', [])).join("\n")
      when 403
        raise Travis::API::V3::InsufficientAccess, response.body['rejection_code']
      when 404
        raise Travis::API::V3::NotFound, response.body.fetch('errors', response.body.fetch('Errors', [])).join("\n")
      when 422
        raise Travis::API::V3::UnprocessableEntity, response.body.fetch('errors', response.body.fetch('Errors', [])).join("\n")
      else
        raise Travis::API::V3::ServerError, 'Artifacts API failed'
      end
    end

    def connection(timeout: 10)
      @connection ||= Faraday.new(url: artifacts_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.basic_auth '_', artifacts_auth_key
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.options[:open_timeout] = timeout
        conn.options[:timeout] = timeout
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        conn.adapter :net_http
      end
    end

    def artifacts_url
      Travis.config.artifacts.url || raise(ConfigurationError, 'No artifacts url configured')
    end

    def artifacts_auth_key
      Travis.config.artifacts.auth_key || raise(ConfigurationError, 'No artifacts auth key configured')
    end

    def query_string_from_params(params)
      params.delete_if { |_, v| v.nil? || v.empty? }.to_query
    end
  end
end