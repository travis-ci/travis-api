describe 'Repos', set_app: true do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  it 'GET /svenfuchs/minimal.png' do
    response = get '/svenfuchs/minimal.png'
    expect(response.status).to eq(200)
  end

  it 'GET /svenfuchs/minimal/cc.xml' do
    response = get '/svenfuchs/minimal/cc.xml'
    expect(response.status).to eq(302)
    expect(response.headers['Location']).to eq('http://example.org/repos/svenfuchs/minimal/cc.xml')
  end

  it 'GET svenfuchs/minimal/cc.xml Accept: */*' do
    response = get "svenfuchs/minimal/cc.xml", {}, { 'HTTP_ACCEPT' => '*/*' }
    expect(response.status).to eq(302)
    expect(response.headers['Location']).to eq('http://example.org/repos/svenfuchs/minimal/cc.xml')
  end

  it 'GET /repositories/svenfuchs/minimal' do
    response = get '/repositories/svenfuchs/minimal'
    expect(response).to deliver_json_for(repo, version: 'v1')
  end
end
