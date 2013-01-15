require 'spec_helper'

describe Travis::Api::App::Endpoint::Artifacts do
  let(:artifact) { Factory(:log) }
  let(:id) { artifact.id }

  describe 'GET /artifacts/:id' do
    it 'loads the artifact' do
      get("/artifacts/#{id}", {}, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01').should be_ok
    end
  end

  describe 'GET /artifacts/:id.txt' do
    it 'loads the artifact' do
      response = get("/artifacts/#{id}.txt", {})

      response.should be_ok
      response.body.should == artifact.content
      response.headers['Content-Disposition'].should == "inline; filename=\"#{artifact.id}\""
    end

    it 'sets Content-Disposition to attachment with attachment=true param' do
      response = get("/artifacts/#{id}.txt", {'attachment' => true})

      response.should be_ok
      response.body.should == artifact.content
      response.headers['Content-Disposition'].should == "attachment; filename=\"#{artifact.id}\""
    end
  end
end
