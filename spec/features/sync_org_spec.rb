require 'rails_helper'

RSpec.feature 'Sync with GitHub for all users in an organization', js: true, type: :feature do
  before do
    service = instance_double(Services::Organization::Sync)
    allow(Services::Organization::Sync).to receive(:new).with(organization).and_return(service)
    allow(service).to receive(:call).and_return(true)
  end
  let!(:organization) { create(:organization, users: [create(:user)]) }

  scenario 'Syncing several users' do
    visit "/organizations/#{organization.id}/members"
    find_button('Sync org').trigger('click')

    expect(page).to have_text('Triggered sync for Organization travis-pro')
  end
end
