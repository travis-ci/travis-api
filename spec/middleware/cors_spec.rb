require 'spec_helper'

describe Travis::Api::App::Middleware::Cors do
  before do
    mock_app do
      use Travis::Api::App::Middleware::Cors
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
      headers['Access-Control-Expose-Headers'].should == "Content-Type"
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
      headers['Access-Control-Expose-Headers'].should == "Content-Type"
    end

    it 'sets Access-Control-Allow-Methods' do
      headers['Access-Control-Allow-Methods'].should == "GET, POST, PATCH, PUT, DELETE"
    end

    it 'sets Access-Control-Allow-Headers' do
      headers['Access-Control-Allow-Headers'].should == "Content-Type, Authorization, Accept"
    end
  end
end
