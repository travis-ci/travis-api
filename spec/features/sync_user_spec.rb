require 'rails_helper'
require 'shared/vcs'

RSpec.feature 'Sync with VCS for a single user', js: true, type: :feature do
  include_context 'vcs'

  let!(:user) { create(:user) }

  scenario 'Syncing a user' do
    visit "/users/#{user.id}"

    stub_request(:post, "#{url}/users/#{user.id}/sync_data")
      .with(headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: '', headers: {})

    find_button('Sync').trigger('click')

    expect(page).to have_text('Triggered sync with VCS.')
  end
end
