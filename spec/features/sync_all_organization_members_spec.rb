require 'rails_helper'
require 'shared/vcs'

RSpec.feature 'Sync with VCS for all users in an organization', js: true, type: :feature do
  include_context 'vcs'

  let!(:katrin)       { create(:user, login: 'lisbethmarianne') }
  let!(:aly)          { create(:user, login: 'sinthetix') }
  let!(:organization) { create(:organization, users: [katrin, aly]) }

  scenario 'Syncing several users' do
    visit "/organizations/#{organization.id}/members"

    [katrin.id, aly.id].each do |user_id|
      stub_request(:post, "#{url}/users/#{user_id}/sync_data")
          .with(headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: '', headers: {})
    end

    find_button('Sync users').trigger('click')

    expect(page).to have_text('Triggered sync with VCS for all users in the organization.')
  end
end
