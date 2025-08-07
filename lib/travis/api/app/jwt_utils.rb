class Travis::Api::App
  module JWTUtils
    def extract_jwt_token(request)
      request.env['HTTP_AUTHORIZATION']&.split&.last
    end

    def verify_jwt(request)
      # payload = {
      #   email: 'viktorija.krivokapic1+1@gmail.com',
      #   login: 'viktorijaTravisAssembla380',
      #   id: 'cs0JUKBgSr8ioDLJtkgGFV',
      #   name: 'viktorija devtactics',
      #   space_id: 'crofDwBRKr8kdd0NKLjkMA',
      #   repository_id: 'cajjvcB_qr8iot_O0clYmL',
      #   access_token: 'e6dea10f2ea91562f8fcf44eff6588e9',
      #   refresh_token: '5dfe4814cea729ea4b0ce97ba8d4aa41',
      #   exp: Time.now.to_i + (3600 * 100) # 7 days expiration
      # }

      # secret = Travis.config.assembla_jwt_secret
      # token = JWT.encode(payload, secret, 'HS256')
      # puts "Generated JWT: #{token}"

      # Generated JWT at 3rd aug 2025 at 4:15 am For staging secret:
      # eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6InZpa3RvcmlqYS5rcml2b2thcGljMSsxQGdtYWlsLmNvbSIsImxvZ2luIjoidmlrdG9yaWphVHJhdmlzQXNzZW1ibGEzODAiLCJpZCI6ImNzMEpVS0JnU3I4aW9ETEp0a2dHRlYiLCJuYW1lIjoidmlrdG9yaWphIGRldnRhY3RpY3MiLCJzcGFjZV9pZCI6ImNyb2ZEd0JSS3I4a2RkME5LTGprTUEiLCJyZXBvc2l0b3J5X2lkIjoiY2FqanZjQl9xcjhpb3RfTzBjbFltTCIsImFjY2Vzc190b2tlbiI6ImU2ZGVhMTBmMmVhOTE1NjJmOGZjZjQ0ZWZmNjU4OGU5IiwicmVmcmVzaF90b2tlbiI6IjVkZmU0ODE0Y2VhNzI5ZWE0YjBjZTk3YmE4ZDRhYTQxIiwiZXhwIjoxNzU0NTM2NTc0fQ.IoNhjpl3DwK5HVqO5FiQiylqKkKiRDV8qaLiFgcv01k


      # payload = {
      #   email: 'viktorija.krivokapic1+1@gmail.com',
      #   login: 'viktorijaTravisAssembla380',
      #   id: 'cs0JUKBgSr8ioDLJtkgGFV',
      #   name: 'viktorija devtactics',
      #   space_id: 'crofDwBRKr8kdd0NKLjkMA',
      #   repository_id: 'cajjvcB_qr8iot_O0clYmL',
      #   access_token: 'e6dea10f2ea91562f8fcf44eff6588e9',
      #   refresh_token: '5dfe4814cea729ea4b0ce97ba8d4aa41',
      #   exp: Time.now.to_i + (3600 * 100) # 7 days expiration
      # }

      # secret = 'N3jANvlyDRvzYPAXlZi90zlow8kzgmMKFCBnZ0sB7mxGmmyVYF0vF0V7Go23Of4T'
      # token = JWT.encode(payload, secret, 'HS256')
      # puts "Generated JWT: #{token}"
      # Generated JWT at 3rd aug 2025 at 4:15 am For staging dev secret:
      # eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6InZpa3RvcmlqYS5rcml2b2thcGljMSsxQGdtYWlsLmNvbSIsImxvZ2luIjoidmlrdG9yaWphVHJhdmlzQXNzZW1ibGEzODAiLCJpZCI6ImNzMEpVS0JnU3I4aW9ETEp0a2dHRlYiLCJuYW1lIjoidmlrdG9yaWphIGRldnRhY3RpY3MiLCJzcGFjZV9pZCI6ImNyb2ZEd0JSS3I4a2RkME5LTGprTUEiLCJyZXBvc2l0b3J5X2lkIjoiY2FqanZjQl9xcjhpb3RfTzBjbFltTCIsImFjY2Vzc190b2tlbiI6ImU2ZGVhMTBmMmVhOTE1NjJmOGZjZjQ0ZWZmNjU4OGU5IiwicmVmcmVzaF90b2tlbiI6IjVkZmU0ODE0Y2VhNzI5ZWE0YjBjZTk3YmE4ZDRhYTQxIiwiZXhwIjoxNzU0NTM3MTUyfQ.CnEsqTvFrSSfW23D6qdDynCRB51ea2kTXNiHLPh8w-I


      
      # for staging dev, user ID:125840 on 5th Aug 2025
      # payload = {
      #   email: 'oksana.hinailo+user-0408@devtactics.net',
      #   login: 'user-0408',
      #   id: 'aZjjsYCrir8ikSdMBSqNIq',
      #   name: 'user-0408 test',
      #   space_id: 'bkNxmOCC0r8j7dtK6LbPF5',
      #   repository_id: 'cldIxeCC0r8j7dtK6LbPF5',
      #   refresh_token: '1adee72d172bd230203188153dca302d',
      #   exp: Time.now.to_i + (3600 * 100) # 7 days expiration
      # }

      # secret = 'N3jANvlyDRvzYPAXlZi90zlow8kzgmMKFCBnZ0sB7mxGmmyVYF0vF0V7Go23Of4T'
      # token = JWT.encode(payload, secret, 'HS256')
      # puts "Generated JWT: #{token}"
      # Generated JWT: eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6Im9rc2FuYS5oaW5haWxvK3VzZXItMDQwOEBkZXZ0YWN0aWNzLm5ldCIsImxvZ2luIjoidXNlci0wNDA4IiwiaWQiOiJhWmpqc1lDcmlyOGlrU2RNQlNxTklxIiwibmFtZSI6InVzZXItMDQwOCB0ZXN0Iiwic3BhY2VfaWQiOiJia054bU9DQzByOGo3ZHRLNkxiUEY1IiwicmVwb3NpdG9yeV9pZCI6ImNsZEl4ZUNDMHI4ajdkdEs2TGJQRjUiLCJyZWZyZXNoX3Rva2VuIjoiMWFkZWU3MmQxNzJiZDIzMDIwMzE4ODE1M2RjYTMwMmQiLCJleHAiOjE3NTQ3NDc4NDd9.ArsRunhJTHsC6KeRjvThC4gynSWtvPsnqqxgn7Eorf4



      token = extract_jwt_token(request)
      
      halt 401, { error: "Missing JWT" } unless token
      
      begin
        decoded, = JWT.decode(token, Travis.config.assembla_jwt_secret, true, algorithm: 'HS256')
        decoded
      rescue JWT::DecodeError => e
        halt 401, { error: "Invalid JWT: #{e.message}" }
      end
    end
  end
end
