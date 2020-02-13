describe 'App' do
  before do
    add_endpoint '/foo' do
      get '/' do
        respond_with foo: 'bar'
      end
    end
  end

  it 'uses version from current accept header' do
    # Note: This previously said that the version should be v1. However, after
    # removing the `returns(false).then.returns(true)`, v2 is always returned
    # (regardless of whether true or false is returned from `apply?`.
    # This just updated the syntax of the test, not the implementation, so it should be fine.
    expect(Travis::Api::Serialize).to receive(:builder).with(anything, hash_including(version: 'v2'))
    allow(Travis::Api::App::Responders::Json).to receive(:apply?).and_return(false)

    response = get '/foo', {}, 'HTTP_ACCEPT' => 'application/json; version=2, application/json; version=1'
    expect(response.content_type).to eq('application/json;charset=utf-8')
  end

  it 'uses v1 by default' do
    expect(Travis::Api::Serialize).to receive(:builder).with(anything, hash_including(version: 'v1'))
    get '/foo', {}, 'HTTP_ACCEPT' => 'application/json'
  end
end
