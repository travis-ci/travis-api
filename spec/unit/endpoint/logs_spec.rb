describe Travis::Api::App::Endpoint::Logs, set_app: true do
  let(:job)  { Factory(:test) }

  describe "GET /logs/:id/" do
    it "finds log successfully" do
      get("/logs/#{job.log.id}", {}, "HTTP_ACCEPT" => "application/vnd.travis-ci.2+json, */*; q=0.01").should be_ok
    end
  end
end
