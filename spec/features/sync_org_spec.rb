require 'rails_helper'
require 'shared/vcs'

RSpec.feature 'Sync with VCS for all users in an organization', js: true, type: :feature do
  include_context 'vcs'

  let!(:organization) { create(:organization, users: [create(:user)]) }

  scenario 'Syncing several users' do
    stub_request(:post, "#{url}/organizations/#{organization.id}/sync_data")
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: 200, body: '', headers: {})

    service = instance_double(Services::Organization::Sync)
    response = double(Services::Organization::Sync)
    allow(service).to receive(:call).and_return(response)
    allow(response).to receive(:success?).and_return(true)

    visit "/organizations/#{organization.id}/members"
    find_button('Sync org').trigger('click')

    expect(page).to have_text('Triggered sync for Organization travis-pro')
  end

  scenario 'Is not Syncing' do
    stub_request(:post, "#{url}/organizations/#{organization.id}/sync_data")
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: 500, body: '', headers: {})

    service = instance_double(Services::Organization::Sync)
    response = double(Services::Organization::Sync)
    allow(service).to receive(:call).and_return(response)
    allow(response).to receive(:success?).and_return(false)

    visit "/organizations/#{organization.id}/members"
    find_button('Sync org').trigger('click')

    expect(page).to have_text('Sync for Organization travis-pro failed')
  end
end
