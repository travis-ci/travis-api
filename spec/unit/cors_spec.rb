describe Travis::Api::App::Cors do
  before do
    mock_app do
      use Travis::Api::App::Cors
      get('/check_cors') { 'ok' }
    end
  end

  describe 'normal request' do
    before { expect(get('/check_cors')).to be_ok }

    it 'sets Access-Control-Allow-Origin' do
      expect(headers['Access-Control-Allow-Origin']).to eq("*")
    end

    it 'sets Access-Control-Allow-Credentials' do
      expect(headers['Access-Control-Allow-Credentials']).to eq("true")
    end

    it 'sets Access-Control-Expose-Headers' do
      expect(headers['Access-Control-Expose-Headers']).to eq("Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Request-ID")
    end
  end

  describe 'OPTIONS requests' do
    before { expect(options('/')).to be_ok }

    it 'sets Access-Control-Allow-Origin' do
      expect(headers['Access-Control-Allow-Origin']).to eq("*")
    end

    it 'sets Access-Control-Allow-Credentials' do
      expect(headers['Access-Control-Allow-Credentials']).to eq("true")
    end

    it 'sets Access-Control-Expose-Headers' do
      expect(headers['Access-Control-Expose-Headers']).to eq("Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Request-ID")
    end

    it 'sets Access-Control-Allow-Methods' do
      expect(headers['Access-Control-Allow-Methods']).to eq("HEAD, GET, POST, PATCH, PUT, DELETE")
    end

    it 'sets Access-Control-Allow-Headers' do
      expect(headers['Access-Control-Allow-Headers']).to eq("Content-Type, Authorization, Accept, If-None-Match, If-Modified-Since, X-User-Agent, X-Client-Release, Travis-API-Version, Trace")
    end

    it 'sets Access-Control-Max-Age' do
      expect(headers['Access-Control-Max-Age']).to eq("86400")
    end
  end
end
