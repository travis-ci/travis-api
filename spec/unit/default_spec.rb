describe Travis::Api::App::Endpoint::Home, set_app: true do
  describe 'GET /' do
    it 'replies with a json response by default' do
      get('/')["Content-Type"].should include("json")
    end

    it 'redirects HTML requests to /docs' do
      get '/', {}, 'HTTP_ACCEPT' => 'text/html'
      status.should == 302
      headers['Location'].should end_with('/docs/')
    end
  end
end
