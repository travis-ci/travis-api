class Travis::Api::App
  module JWTUtils
    def extract_jwt_token(request)
      request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    end

    def verify_jwt(request)
      secret = Travis.config.assembla_jwt_secret
      token = extract_jwt_token(request)
      
      halt 401, { error: "Missing JWT" }.to_json  unless token
      
      begin
        decoded, = JWT.decode(token, secret, true, { algorithm: 'HS256' })
        decoded
      rescue JWT::DecodeError => e
        halt 401, { error: "Invalid JWT: #{e.message}" }.to_json
      end
    end
  end
end
