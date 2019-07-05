require 'rails_helper'

RSpec.feature 'Organization page gives the information about organizaton account on GitHub', js: true, type: :feature do
  let!(:katrin)                  { create(:user, login: 'lisbethmarianne') }
  let!(:aly)                     { create(:user, login: 'sinthetix') }
  let!(:organization_gh)         { create(:organization_with_github_id, users: [katrin, aly]) }
  let!(:organization_no_gh)      { create(:organization, users: [katrin, aly]) }
  let!(:organization_w_repo)     { create(:organization_with_ghid_repo, users: [katrin, aly]) }
  let!(:organization_w_members)  { create(:organization, users: [katrin, aly]) }
  let!(:organization_memberless) { create(:organization, users: []) }

  scenario 'GH Integration info is not displayed for organization without github_id' do
    visit "/organizations/#{organization_no_gh.id}"
    expect(page).not_to have_text('Service Hook')
    expect(page).not_to have_text('GitHub App installed with')
  end

  scenario 'GH Integration info is displayed for organization with github_id' do
    visit "/organizations/#{organization_gh.id}"
    expect(page).to have_text('GitHub App installed with')
  end

  scenario 'Service Hook text is displayed for organization with a service hook available' do
    expect_any_instance_of(Services::Repository::CheckHook).
        to receive(:call).and_return(organization_w_repo.repositories.first)
    visit "/organizations/#{organization_w_repo.id}"
    expect(page).to have_text('Service Hook')

  scenario 'Display number of members in organization' do
    visit "/organizations/#{organization_w_members.id}/members"
    expect(page.find_by_id('organization-members-header')).to have_text('Members (2)')
  end

  scenario 'Display \'No members.\' for organization without them' do
    visit "/organizations/#{organization_memberless.id}/members"
    expect(page.find_by_id('organization-members-header')).to have_text('Members')
    expect(page.find_by_id('organization-members-header')).to have_no_text('Members (')
    expect(page).to have_text('No members.')
  end
end
