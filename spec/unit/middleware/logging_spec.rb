describe Travis::Api::App::Middleware::Logging do
  it 'configures ActiveRecord' do
    expect(ActiveRecord::Base.logger).to eq(Travis.logger)
  end

  it 'sets the logger' do
    mock_app do
      use Travis::Api::App::Middleware::Logging
      get '/check_logger' do
        throw unless logger == Travis.logger
        'ok'
      end
    end

    expect(get('/check_logger')).to be_ok
  end
end
