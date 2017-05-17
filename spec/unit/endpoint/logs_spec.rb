describe Travis::Api::App::Endpoint::Logs, set_app: true do
  describe "GET /logs/:id/" do
    before do
      Travis::RemoteLog.stubs(:find_by_id).with(4).returns(Travis::RemoteLog.new(content: '', job_id: 8))
    end

    it 'finds log successfully' do
      get('/logs/4', {}, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01').should be_ok
    end
  end
end
