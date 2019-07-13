require 'rails_helper'

RSpec.feature 'Organization page gives the information about organizaton account on GitHub', js: true, type: :feature do
  let!(:katrin)                  { create(:user, login: 'lisbethmarianne') }
  let!(:aly)                     { create(:user, login: 'sinthetix') }
  let!(:organization_gh)         { create(:organization_with_github_id, users: [katrin, aly]) }
  let!(:organization)      { create(:organization, users: [katrin, aly]) }
  let!(:organization_w_repo)     { create(:organization_with_ghid_repo, users: [katrin, aly]) }
  let!(:organization_w_members)  { create(:organization, users: [katrin, aly]) }
  let!(:organization_memberless) { create(:organization, users: []) }
  let!(:installation)            { create(:installation, owner_id: organization_gh.id)}

  scenario 'GH Integration info - Service Hook - is displayed for organization without installation' do
    visit "/organizations/#{organization.id}"
    expect(page).to have_text('Service Hook')
    expect(page).to have_text('GitHub Integration')
  end

  scenario 'GH Integration info is displayed for organization with github_id' do
    visit "/organizations/#{organization_gh.id}"

  end

  scenario 'Service Hook text is displayed for organization with a service hook available' do

    visit "/organizations/#{organization_gh.id}"

    expect(page).to have_text('GitHub Integration')
    expect(page).to have_text("GitHub App installed with id: #{installation.id}")
    expect(page).to have_text("and github_id: #{installation.github_id}")
    expect(page).to have_text('[Manage repos link]')
  end

  scenario 'Display number of members in organization' do
    visit "/organizations/#{organization_gh.id}/members"
    expect(page.find_by_id('organization-members-header')).to have_text('Members (2)')
  end

  scenario 'Display \'No members.\' for organization without them' do
    visit "/organizations/#{organization_memberless.id}/members"
    expect(page.find_by_id('organization-members-header')).to have_text('Members')
    expect(page.find_by_id('organization-members-header')).to have_no_text('Members (')
    expect(page).to have_text('No members.')
  end
end
