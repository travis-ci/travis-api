require 'rails_helper'

RSpec.feature 'Organization page gives the information about organizaton account on GitHub', js: true, type: :feature do
  let!(:katrin)                  { create(:user, login: 'lisbethmarianne') }
  let!(:aly)                     { create(:user, login: 'sinthetix') }
  let!(:organization_w_members)  { create(:organization, users: [katrin, aly]) }
  let!(:organization_memberless) { create(:organization, users: []) }

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
