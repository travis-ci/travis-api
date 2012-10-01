require 'spec_helper'

describe Travis::Api::App::Middleware::Logging do
  it 'configures ActiveRecord' do
    ActiveRecord::Base.logger.should == Travis.logger
  end

  it 'sets the logger' do
    mock_app do
      use Travis::Api::App::Middleware::Logging
      get '/check_logger' do
        logger.should == Travis.logger
        'ok'
      end
    end

    get('/check_logger').should be_ok
  end
end
