require 'rails_helper'

RSpec.feature 'Unknown controller redirects spec', js: true, type: :feature do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository) }

  before {
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  }

  describe 'canonical_route' do
    scenario 'displays /?q=owner for valid owner' do
      visit "/#{user.login}"
      expect(page.current_url).to have_text("/?q=#{user.login}")
    end

    scenario 'redirects to :not_found for invalid user or organization' do
      visit '/fake_user_organization'
      expect(page).to have_text('Not Found!')
    end
  end

  describe 'repository' do
    scenario 'displays repository page for valid repository path' do
      visit "/#{repository.owner_name}/#{repository.name}"
      expect(page).to have_text("#{repository.name}")
    end

    scenario 'redirects to :not_found for invalid repository path' do
      visit '/fake_owner/fake_repo'
      expect(page).to have_text('Not Found!')
    end
  end
end