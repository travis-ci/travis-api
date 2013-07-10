require 'spec_helper'

describe Travis::Api::App::Endpoint::Jobs do
  let(:job) { Factory(:test) }

  it "GET /jobs/:id/metadata" do
    get("/jobs/#{job.id}/metadata", {}, "HTTP_ACCEPT" => "application/vnd.travis-ci.2+json, */*; q=0.01").should be_ok
  end
end
