module Support
  module GdprSpecHelper
    def stub_gdpr_request(method, path, user_id:)
      url = URI(gdpr_url).tap do |url|
        url.path = path
      end.to_s
      stub_request(method, url).with(headers: { 'Authorization' => "Token token=\"#{gdpr_auth_token}\"", 'X-Travis-User-Id' => user_id, 'X-Travis-Source' => 'travis-api' })
    end
  end
end
