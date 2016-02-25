require './lib/travis_authentication'

Her::API.setup url: 'https://api.travis-ci.org' do |c|
  # Request
  c.use TravisAuthentication
  c.use Faraday::Request::UrlEncoded

  # Response
  c.use Her::Middleware::DefaultParseJSON

  # Adapter
  c.use Faraday::Adapter::NetHttp
end