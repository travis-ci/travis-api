require 'rails_helper'

RSpec.feature 'Unknown controller redirects spec', js: true, type: :feature do
  let!(:build)        { create(:build) }
  let!(:job)          { create(:job) }
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:repository)   { create(:repository) }

  before { allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([]) }

  describe 'build' do
    scenario 'display proper build using long build path link' do
      visit "/some_owner/some_repo/builds/#{build.id}"
      expect(page).to have_text("#{build.number}")
    end

    scenario 'shorter link to builds is used' do
      visit "/some_owner/some_repo/builds/#{build.id}"
      expect(page.current_url).to have_text("/builds/#{build.id}")
      expect(page.current_url).to_not have_text("some_owner/some_repo/builds/#{build.id}")
    end
  end

  describe 'canonical_route' do
    scenario 'displays /?q=owner for valid owner' do
      visit "/#{user.login}"
      expect(page.current_url).to have_text("/?q=#{user.login}")
      expect(page).to have_text("#{user.login}")
    end

    scenario 'redirects to :not_found for invalid user or organization' do
      visit '/fake_user_organization'
      expect(page).to have_text('Not Found!')
    end
  end

  describe 'job' do
    scenario 'display proper job using long job path link' do
      visit "/some_owner/some_repo/jobs/#{job.id}"
      expect(page).to have_text("#{job.number}")
    end

    scenario 'shorter link to jobs is used' do
      visit "/some_owner/some_repo/jobs/#{job.id}"
      expect(page.current_url).to have_text("/jobs/#{job.id}")
      expect(page.current_url).to_not have_text("some_owner/some_repo/jobs/#{job.id}")
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