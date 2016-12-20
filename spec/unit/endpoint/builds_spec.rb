describe Travis::Api::App::Endpoint::Builds, set_app: true do
  include Travis::Testing::Stubs

  it 'works with default options' do
    response = get('/repos.json', {})
    response.status.should == 403
  end

  context '/repos.json is requested' do
    before :each do
      @plain_response_body = get('/repos.json').body
    end

    context 'when `pretty=true` is given' do
      it 'prints pretty formatted data' do
        response = get('/repos.json?pretty=true')
        response.status.should == 403
      end
    end

    context 'when `pretty=1` is given' do
      it 'prints pretty formatted data' do
        response = get('/repos.json?pretty=1')
        response.status.should == 403
      end
    end

    context 'when `pretty=bogus` is given' do
      it 'prints plain-formatted data' do
        response = get('/repos.json?pretty=bogus')
        response.status.should == 403
      end
    end
  end

end
