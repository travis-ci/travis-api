class TravisAuthentication < Faraday::Middleware
  def call(env)
    env[:request_headers]['Authorization'] = 'token D0nqa10GPgIE0Q7rlEIJyQ'
    env[:request_headers]['Travis-API-Version'] = '3'
    env[:request_headers]['User-Agent'] = 'Travis'
    env[:request_headers]['Accept'] = 'application/json'
    @app.call(env)
  end
end