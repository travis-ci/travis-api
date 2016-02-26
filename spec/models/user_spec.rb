require 'rails_helper'

describe User do
  describe '.find' do
    context 'there is a user with an id' do
      it 'finds user 125283' do
        VCR.use_cassette('user_cassette') do
          user = User.find(125283)
          expect(user.login).to eql 'sinthetix'
        end
      end
    end

    context 'there is no user with an id' do
      # TODO: this
      # user = User.find(6) will bring up a not found error
    end

    context 'the user id is invalid' do
      # TODO: this
    end

    context 'with unauthorized access' do
      # TODO: this
      # I took this from betterspecs.org. We need this section but not sure what to do yet.
      # let(:uri) { 'http://api.lelylan.com/types' }
      # before    { stub_request(:get, uri).to_return(status: 401, body: fixture('401.json')) }
      # it "gets a not authorized notification" do
      #  page.driver.get uri
      #  expect(page).to have_content 'Access denied'
      # end
    end
  end
end

