require 'rails_helper'

RSpec.feature 'Load VCS Type', js: true, type: :feature do
  before do
    organization = create(:organization, vcs_type: 'GithubOrganization', login: 'travis')
    visit "/organizations/#{organization.id}"
  end

  scenario 'Load profile URL depending on vcs type' do
    expect(page).to have_text('GithubOrganization')
  end
end