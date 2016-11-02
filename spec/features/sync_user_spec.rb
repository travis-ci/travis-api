require 'rails_helper'

RSpec.feature 'Sync with GitHub for a single user', js: true, type: :feature do
  let!(:user) { create(:user) }

  scenario 'Syncing a user' do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/users/#{user.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/user/#{user.id}/sync").
      to_return(status: 200, body: '', headers: {})

    find_button('Sync').trigger('click')

    expect(page).to have_text('Triggered sync with GitHub.')
  end
end
