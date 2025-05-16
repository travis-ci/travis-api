module Travis::API::V3
  class ArtifactManagerClient
    class ConfigurationError < StandardError; end

    def initialize(user_id)
      @user_id = user_id
    end

    def create(owner:, image_name:, job_restart: false)
      params = {
        owner_type: owner.class.name.downcase,
        id: owner.id,
        name: image_name,
        job_restart:
      }
      handle_errors_and_respond(connection.post("/create", params)) do |body|
        body.include?('image_id')  ? body['image_id'] : false
      end
    rescue Faraday::Error
      raise ArtifactManagerConnectionError
    end

    def use(owner:, image_name:)
      handle_errors_and_respond(connection.get("/image/#{owner.class.name.downcase}/#{owner.id}/#{image_name}")) do |response|
        body.include?('image_id')  ? body['image_id'] : false
      end
    rescue Faraday::Error
      raise ArtifactManagerConnectionError
    end

    def images(owner_type, owner_id)
      response = connection.get("/images?owner_type=#{owner_type}&id=#{owner_id}")
      handle_images_response(response)
    end

    def delete_images(image_ids)
      response = connection.delete('/images') do |req|
        req.body = { image_ids: }.to_json
      end
      handle_errors_and_respond(response)
    end

    private

    def handle_images_response(response)
      handle_errors_and_respond(response) do |r|
        r['images'].map { |image_data| Travis::API::V3::Models::CustomImage.new(image_data) }
      end
    end

    def handle_errors_and_respond(response)
      body = response.body.is_a?(String) && response.body.length.positive? ? JSON.parse(response.body) : response.body

      case response.status
      when 200, 201
        yield(body) if block_given?
      when 202
        true
      when 204
        true
      when 400
        raise Travis::API::V3::ClientError, body['error']
      when 403
        raise Travis::API::V3::InsufficientAccess, body['rejection_code']
      when 404
        raise Travis::API::V3::NotFound, body['error']
      when 422
        raise Travis::API::V3::UnprocessableEntity, body['error']
      else
        raise Travis::API::V3::ServerError, 'Artifact manager failed'
      end
    end

    def connection(timeout: 10)
      @connection ||= Faraday.new(url: artifact_manager_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.request(:authorization, :basic, '_', artifact_manager_auth_key)
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.options[:open_timeout] = timeout
        conn.options[:timeout] = timeout
        conn.adapter :net_http
      end
    end

    def artifact_manager_url
      Travis.config.artifact_manager&.url || raise(ConfigurationError, 'No artifact manager url configured')
    end

    def artifact_manager_auth_key
      Travis.config.artifact_manager&.auth_key || raise(ConfigurationError, 'No artifact manager auth key configured')
    end
  end
end
