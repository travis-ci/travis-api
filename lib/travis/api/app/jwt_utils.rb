class Travis::Api::App
  module JWTUtils
    def extract_jwt_token(request)
      request.env['HTTP_AUTHORIZATION']&.split&.last
    end

    def verify_jwt(request)
      token = extract_jwt_token(request)
      
      halt 401, { error: "Missing JWT" } unless token
      
      begin
        decoded, = JWT.decode(token, Travis.config.assembla_jwt_secret, true, algorithm: 'HS256' )
        decoded
      rescue JWT::DecodeError => e
        halt 401, { error: "Invalid JWT: #{e.message}" }
      end
    end
  end
end
