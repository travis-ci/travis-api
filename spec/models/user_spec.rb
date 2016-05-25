require 'rails_helper'

RSpec.describe User do
  context '.find' do
    it 'finds user 125283', :vcr do
      expect(User.find(125283).login).to eql 'sinthetix'
    end
  end

  context 'there is no user with an id' do
      # TODO: this
      # user = User.find(6) will bring up a not found error
  end

  context 'the user id is invalid' do
      # TODO: this
      # should this just be tied in with no user with id?
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

