describe Travis::Api::App::Endpoint::Home, set_app: true do
  describe 'GET /' do
    it 'replies with a json response by default' do
      expect(get('/')["Content-Type"]).to include("json")
    end

    it 'redirects HTML requests to /docs' do
      get '/', {}, 'HTTP_ACCEPT' => 'text/html'
      expect(status).to eq(302)
      expect(headers['Location']).to end_with('/docs/')
    end

    it 'does not check auth' do
      expect(subject.settings.check_auth?).to eq false
    end
  end
end
