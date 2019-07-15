require 'rails_helper'

RSpec.feature 'Organization page gives the information about organizaton account on GitHub', js: true, type: :feature do
  let!(:katrin)                  { create(:user, login: 'lisbethmarianne') }
  let!(:aly)                     { create(:user, login: 'sinthetix') }
  let!(:organization_w_inst)     { create(:organization, users: [katrin, aly]) }
  let!(:organization)            { create(:organization, users: [katrin, aly]) }
  let!(:organization_memberless) { create(:organization, users: []) }
  let!(:installation)            { create(:installation, owner_id: organization_w_inst.id)}

  scenario 'GH Integration info - Service Hook - is displayed for organization without installation' do
    visit "/organizations/#{organization.id}"
    expect(page).to have_text('Service Hook')
    expect(page).to have_text('GitHub Integration')
  end

  scenario 'Integration info is displayed for organization with an installation' do
    visit "/organizations/#{organization_w_inst.id}"
    expect(page).to have_text('GitHub Integration')
    expect(page).to have_text("GitHub App installed with id: #{installation.id}")
    expect(page).to have_text("and github_id: #{installation.github_id}")
    expect(page).to have_text('[Manage repos link]')
  end

  scenario 'Display number of members in organization' do
    visit "/organizations/#{organization.id}/members"
    expect(page.find_by_id('organization-members-header')).to have_text('Members (2)')
  end

  scenario 'Display \'No members.\' for organization without them' do
    visit "/organizations/#{organization_memberless.id}/members"
    expect(page.find_by_id('organization-members-header')).to have_text('Members')
    expect(page.find_by_id('organization-members-header')).to have_no_text('Members (')
    expect(page).to have_text('No members.')
  end
end
