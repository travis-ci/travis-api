require 'rails_helper'

RSpec.feature 'Sync with GitHub for all users in an organization', js: true, type: :feature do
  let!(:katrin)       { create(:user, login: 'lisbethmarianne') }
  let!(:aly)          { create(:user, login: 'sinthetix') }
  let!(:organization) { create(:organization, users: [katrin, aly]) }

  scenario 'Syncing several users' do
    visit "/organizations/#{organization.id}/members"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/user/#{katrin.id}/sync").
      to_return(status: 200, body: '', headers: {})

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/user/#{aly.id}/sync").
      to_return(status: 200, body: '', headers: {})

    find_button('Sync users').trigger('click')

    expect(page).to have_text('Triggered sync with GitHub for all users in the organization.')
  end
end