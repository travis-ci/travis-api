class Travis::Api::App
  module JWTUtils
    def extract_jwt_token(request)
      request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    end

    def verify_jwt(request, secret)
      token = extract_jwt_token(request)
      raise UnauthorizedError, 'Missing JWT' unless token
      begin
        decoded, = JWT.decode(token, secret, true, { algorithm: 'HS256' })
        decoded
      rescue JWT::DecodeError => e
        raise UnauthorizedError, "Invalid JWT: #{e.message}"
      end
    end

    class UnauthorizedError < StandardError; end
  end
end
