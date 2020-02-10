require 'rails_helper'
require 'shared/vcs'

RSpec.feature 'Check VCS Scopes', js: true, type: :feature do
  include_context 'vcs'

  let!(:user) { create(:user) }

  scenario 'Checking VCS Scopes successed' do
    stub_request(:post, "#{url}/users/#{user.id}/check_scopes")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: '', headers: {})

    visit "/users/#{user.id}"

    find_button('Verify').trigger('click')

    expect(page).to have_text("Scopes checked for #{user.login}")
  end

  scenario 'Checking VCS scopes failed' do
    stub_request(:post, "#{url}/users/#{user.id}/check_scopes")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 500, body: '', headers: {})

    visit "/users/#{user.id}"

    find_button('Verify').trigger('click')

    expect(page).to have_text('Checking scopes failed.')
  end
end
