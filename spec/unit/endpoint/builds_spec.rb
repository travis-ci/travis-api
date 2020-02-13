describe Travis::Api::App::Endpoint::Builds, set_app: true do
  include Travis::Testing::Stubs

  it 'works with default options' do
    response = get('/repos.json', {})
    expect(response.status).to eq(403)
  end

  context '/repos.json is requested' do
    before :each do
      @plain_response_body = get('/repos.json').body
    end

    context 'when `pretty=true` is given' do
      it 'prints pretty formatted data' do
        response = get('/repos.json?pretty=true')
        expect(response.status).to eq(403)
      end
    end

    context 'when `pretty=1` is given' do
      it 'prints pretty formatted data' do
        response = get('/repos.json?pretty=1')
        expect(response.status).to eq(403)
      end
    end

    context 'when `pretty=bogus` is given' do
      it 'prints plain-formatted data' do
        response = get('/repos.json?pretty=bogus')
        expect(response.status).to eq(403)
      end
    end
  end

end
