describe Travis::Api::App::Endpoint::Logs, set_app: true do
  let(:job)  { Factory(:test) }

  describe "GET /logs/:id/" do
    it "finds log successfully" do
      stub_request(
        :any, /#{URI(Travis.config.logs_api.url).hostname}/
      ).to_return(status: 200, body: JSON.dump(content: '', job_id: job.id))
      get("/logs/#{job.log.id}", {}, "HTTP_ACCEPT" => "application/vnd.travis-ci.2+json, */*; q=0.01").should be_ok
    end
  end
end
