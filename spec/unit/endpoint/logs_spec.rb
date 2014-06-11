require 'spec_helper'

describe Travis::Api::App::Endpoint::Logs do
  let(:user) { Factory(:user) }
  let(:job)  { Factory(:test, owner: user, log: Factory(:log)) }
  let(:provider) { Factory(:annotation_provider) }

  describe "GET /logs/:id/" do
    it "finds log successfully" do
      get("/logs/#{job.log.id}", {}, "HTTP_ACCEPT" => "application/vnd.travis-ci.2+json, */*; q=0.01").should be_ok
    end
  end

  describe "PATCH /logs/:id/" do
    before do
      Travis::Services::RemoveLog.any_instance.stubs(:current_user).returns user
    end

    context "user is unauthorized" do
      it 'returns status 401' do
        response = patch("/logs/#{job.id}")
        response.status.should == 401
        JSON.parse(response.body)['error']['message'].should =~ Regexp.new("insufficient permission")
      end
    end

    context 'job is still running' do
      it 'returns status 409' do
        job.stubs(:finished?).returns false
        user.stubs(:permission?).with(:push, anything).returns true

        response = patch("/logs/#{job.id}")
        response.status.should == 409
        JSON.parse(response.body)['error']['message'].should =~ Regexp.new("Job .*is (not |un)finished")
      end
    end
  end
end
