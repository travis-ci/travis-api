describe Travis::Api::App::Cors do
  before do
    mock_app do
      use Travis::Api::App::Cors
      get('/check_cors') { 'ok' }
    end
  end

  describe 'normal request' do
    before { get('/check_cors').should be_ok }

    it 'sets Access-Control-Allow-Origin' do
      headers['Access-Control-Allow-Origin'].should == "*"
    end

    it 'sets Access-Control-Allow-Credentials' do
      headers['Access-Control-Allow-Credentials'].should == "true"
    end

    it 'sets Access-Control-Expose-Headers' do
      headers['Access-Control-Expose-Headers'].should == "Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Request-ID"
    end
  end

  describe 'OPTIONS requests' do
    before { options('/').should be_ok }

    it 'sets Access-Control-Allow-Origin' do
      headers['Access-Control-Allow-Origin'].should == "*"
    end

    it 'sets Access-Control-Allow-Credentials' do
      headers['Access-Control-Allow-Credentials'].should == "true"
    end

    it 'sets Access-Control-Expose-Headers' do
      headers['Access-Control-Expose-Headers'].should == "Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Request-ID"
    end

    it 'sets Access-Control-Allow-Methods' do
      headers['Access-Control-Allow-Methods'].should == "HEAD, GET, POST, PATCH, PUT, DELETE"
    end

    it 'sets Access-Control-Allow-Headers' do
      headers['Access-Control-Allow-Headers'].should == "Content-Type, Authorization, Accept, If-None-Match, If-Modified-Since, X-User-Agent, Travis-API-Version, Trace"
    end

    it 'sets Access-Control-Max-Age' do
      headers['Access-Control-Max-Age'].should == "86400"
    end
  end
end
