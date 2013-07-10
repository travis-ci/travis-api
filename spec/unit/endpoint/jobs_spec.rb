require 'spec_helper'

describe Travis::Api::App::Endpoint::Jobs do
  let(:job) { Factory(:test) }
  let(:provider) { Factory(:metadata_provider) }

  it "GET /jobs/:id/metadata" do
    get("/jobs/#{job.id}/metadata", {}, "HTTP_ACCEPT" => "application/vnd.travis-ci.2+json, */*; q=0.01").should be_ok
  end

  it "PUT /jobs/:id/metadata" do
    response = put("/jobs/#{job.id}/metadata", { "username" => provider.api_username, "key" => provider.api_key, "description" => "Foobar" }, "HTTP_ACCEPT" => "application/vnd.travis-ci.2+json, */*; q=0.01").should be_successful
  end
end
