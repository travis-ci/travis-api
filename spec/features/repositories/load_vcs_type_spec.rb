require 'rails_helper'

RSpec.feature 'Load VCS Type', js: true, type: :feature do
  let!(:repo) { create(:repository) }

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])

    visit "/repositories/#{repo.id}"
  end

  scenario 'Load profile URL depending on vcs type' do
    expect(page).to have_text('GithubRepository')
  end
end
