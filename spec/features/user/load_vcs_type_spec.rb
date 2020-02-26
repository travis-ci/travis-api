require 'rails_helper'

RSpec.feature 'Load VCS Type', js: true, type: :feature do
  before do
    user = create(:user, vcs_type: 'GithubUser', login: 'travis')
    visit "/users/#{user.id}"
  end

  scenario 'Load profile URL depending on vcs type' do
    expect(page).to have_text('GithubUser')
  end
end
