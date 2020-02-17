describe 'Branches', set_app: true do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'GET /branches?repository_id=:repository_id' do
    response = get '/branches', { repository_id: repo.id }, headers
    expect(response).to deliver_json_for(repo.last_finished_builds_by_branches, version: 'v2', type: 'branches')
  end
end
