require 'rails_helper'
require 'support/auth_helper'

RSpec.describe UsersController, type: :controller do
  include AuthHelper

  describe 'POST #update_trial_builds' do
    context 'Topaz' do
      let!(:user) { create(:user) }
      let!(:event) { { :timestamp => Time.now,
                       :owner => { :id => user.id, :name=>'Mr. T', :login=>'example', :type=>'User' },
                       :data=>{ :trial_builds_added=>60, :previous_builds=>10 },
                       :type=>:trial_builds_added } }
      before(:each) { admin_login }

      # This part might need to go in the test for the concern not here
      WebMock.stub_request(:get, "https://topaz-fake.travis-ci.com/builds_provided/1").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => '', :headers => {})
    end
  end
end
