require 'spec_helper'

describe 'Uptime' do
  after do
    ActiveRecord::Base.connection.unstub(:execute)
  end

  it 'returns a 200 and ok when the request was successful' do
    response = get '/uptime'
    response.status.should == 200
    response.body.should == "OK"
  end

  it "returns a 500 when the query wasn't successful" do
    ActiveRecord::Base.connection.stubs(:execute).raises(StandardError, 'error!')
    response = get '/uptime'
    response.status.should == 500
    response.body.should == "Error: error!"
  end
end
