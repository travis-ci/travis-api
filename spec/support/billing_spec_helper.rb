module Support
  module BillingSpecHelper
    def stub_billing_request(method, path, auth_key:, user_id:)
      url = URI(billing_url).tap do |url|
        url.path = path
      end.to_s
      WebMock.stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id , "Content-Type"=>"application/x-www-form-urlencoded", "User-Agent"=>"Faraday v0.9.2"})
    end

    def stub_billing_csv_request(method, path, auth_key:)
      url = URI(billing_url).tap do |url|
        binding.pry
        url.path = path
      end.to_s
      WebMock.stub_request(method, url).with(headers: { 'Authorization'=>"Token token=#{auth_key}" , "User-Agent"=>"Faraday v0.9.2"})
    end
  end
end