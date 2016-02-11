require 'test_helper'

describe User, '.find' do
  context 'there is a user with id 125283' do
    it 'finds user 125283' do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get '/user/125283', {'Accept' => 'application/json'}
      end
    end
    User.find(125283).should == 'sinthetix'
  end
end