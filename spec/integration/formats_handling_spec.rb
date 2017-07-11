describe 'App', set_app: true do
  before do
    add_endpoint '/foo' do
      get '/' do
        respond_with Travis::RemoteLog.new
      end

      get '/hash' do
        respond_with foo: 'bar'
      end
    end
  end

  it 'gives priority to format given the url' do
    response = get '/foo.txt', {}, 'HTTP_ACCEPT' => 'application/json'
    response.content_type.should =~ /^text\/plain/
  end

  it 'responds with first available type' do
    response = get '/foo', {}, 'HTTP_ACCEPT' => 'image/jpeg, application/json'
    response.content_type.should =~ /^application\/json/
  end

  it 'responds with 406 if server can\'t use any mime type' do
    response = get '/foo/hash', {}, 'HTTP_ACCEPT' => 'text/plain, image/jpeg'
    response.status.should == 406
  end
end
