ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'database_cleaner'
require 'sinatra/test_helpers'
require 'logger'
require 'gh'
require 'multi_json'

require 'travis/api/app'
require 'travis/testing'
require 'travis/testing/scenario'
require 'travis/testing/factories'
require 'travis/testing/matchers'
require 'support/matchers'
require 'support/formats'

Travis.logger = Logger.new(StringIO.new)
Travis::Api::App.setup
Travis.config.client_domain = "www.example.com"
Travis.config.endpoints.ssh_key = true

module TestHelpers
  include Sinatra::TestHelpers

  def custom_endpoints
    @custom_endpoints ||= []
  end

  def add_settings_endpoint(name, options = {})
    if options[:singleton]
      Travis::Api::App::SingletonSettingsEndpoint.subclass(name)
    else
      Travis::Api::App::SettingsEndpoint.subclass(name)
    end
    set_app Travis::Api::App.new
  end

  def add_endpoint(prefix, &block)
    endpoint = Sinatra.new(Travis::Api::App::Endpoint, &block)
    endpoint.set(prefix: prefix)
    set_app Travis::Api::App.new
    custom_endpoints << endpoint
  end

  def parsed_body
    MultiJson.decode(body)
  end
end

RSpec.configure do |c|
  c.mock_framework = :mocha
  c.expect_with :rspec, :test_unit
  c.include TestHelpers

  c.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
    Scenario.default
  end

  c.before :each do
    DatabaseCleaner.start
    ::Redis.connect(url: Travis.config.redis.url).flushdb
    Travis.config.oauth2 ||= {}
    Travis.config.oauth2.scope = "user:email,public_repo"
    set_app Travis::Api::App.new
  end

  c.after :each do
    DatabaseCleaner.clean
    custom_endpoints.each do |endpoint|
      endpoint.superclass.direct_subclasses.delete(endpoint)
    end
  end
end

TEST_PRIVATE_KEY = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA6Dm1n+fc0ILeLWeiwqsWs1MZaGAfccrmpvuxfcE9UaJp2POy
079g+mdiBgtWfnQlU84YX31rU2x9GJwnb8G6UcvkEjqczOgHHmELtaNmrRH1g8qO
fJpzXB8XiNib1L3TDs7qYMKLDCbl2bWrcO7Dol9bSqIeb7f9rzkCd4tuXObL3pMD
/VIW5uzeVqLBAc0Er+qw6U7clnMnHHMekXt4JSRfauSCxktR2FzigoQbJc8t4iWO
rmNi5Q84VkXB3X7PO/eajUw+RJOl6FnPN1Zh08ceqcqmSMM4RzeVQaczXg7P92P4
mRF41R97jIJyzUGwheb2Z4Q2rltck4V7R5BvMwIDAQABAoIBAE4O3+MRH+MiqiXe
+RGwSqAaZab08Hzic+dbIQ0hQEhJbITVXZ3ZbXKd/5ACjZ9R0R47X2vxj3rqM55r
FsJ0/vjxrQcHlp81uvbWLgZvF1tDdyBGnOB7Vh14AgQoszCuYdxPZu8BVZXPGWG1
tBvw1eelX91VYx+wW+BjLFYckws8kPCPY6WEnng0wQGShGqyTOJa1T4M1ethHYF+
ddNx+fVLkEf2vL59popuJMOAyVa1jvU7D3VZ67qhlxWAvQxZeEP0vFZHeWPjvRF1
orxiGuwLCG+Rgq1XSVJjMNf1qE3gZTlDg+u3ORKbRx2xlhiqpkHxLx7QtCmELwtD
Dqvf8ukCgYEA/SoQwyfMp4t19FLI4tV0rp3Yn7ZSAqRtMVrLVAIQoJzDXv9BaJFS
xb6enxRAjy+Rg10H8ijh8Z9Z3a4g3JViHQsWMrf9rL2/7M07vraIUIQoVo7yTeGa
MXnTuKmBZFGEAM9CzqAVao1Om10TRFNLgiLAU3ZEFi8J1DYWkhzrJp0CgYEA6tOa
V15MP3sJSlOTszshXKbwf6iXfjHbdpGUXmd9X3AMzOvl/CEGS2q46lwJISubHWKF
BOKk1thumM4Zu6dx89hLEoXhFycgUV/KJYl54ZfhY079Ri7SZUYIqDR04BRJC2d6
mO16Y//UwqgTaZ/lS/S791iWPTjVNEgSlRbQHA8CgYALiOEeoy+V6qrDKQpyG1un
oRV/oWT3LdqzxvlAqJ9tUfcs2uB2DTkCPX8orFmMrJQqshBsniQ9SA9mJErnAf9o
Z1rpkKyENFkMRwWT2Ok5EexslTLBDahi3LQi08ZLddNX3hmjJHQVWL7eIU2BbXIh
ScgNhXPwts/x1U0N9zdXmQKBgQC4O6W2cAQQNd5XEvUpQ/XrtAmxjjq0xjbxckve
OQFy0/0m9NiuE9bVaniDXgvHm2eKCVZlO8+pw4oZlnE3+an8brCParvrJ0ZCsY1u
H8qgxEEPYdRxsKBe1jBKj0U23JNmQBw+SOqh9AAfbDA2yTzjd7HU4AqXI7SZ3QW/
NHO33wKBgQCqxUmocyqKy5NEBPMmeHWapuSY47bdDaE139vRWV6M47oxzxF8QnQV
1TGWsshK04QO8wsfzIa9/SjZkU17QVkz7LXbq4hPmiZjhP/H+roCeoDEyHFdkq6B
bm/edpYemlJlQhEYtecwvD57NZbVuaqX4Culz9WdSsw4I56hD+QjHQ==
-----END RSA PRIVATE KEY-----
"
