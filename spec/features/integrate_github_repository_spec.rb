require 'rails_helper'

RSpec.feature 'Integrate Github Repository', js: true, type: :feature do
  let!(:integrated_repo) { create(:repo_with_users, active: true, managed_by_installation_at: Time.current) }
  let!(:repo) { create(:repo_with_users, active: true) }
  let(:gh) do
    [{
      'name' => 'travis',
      'active' => true,
      'events' => %w[pull_request push],
      'config' => { 'domain' => 'notify.fake.travis-ci.com' }
    }]
  end

  before { allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([]) }

  scenario 'repo uses a GitHub App Installation' do
    visit "/repositories/#{integrated_repo.id}"

    within(:css, '.gh-integration-container') do
      expect(page).to have_text('This repo uses a GitHub App Installation')
    end

    within(:css, '.activation-container') do
      expect(page).to have_text('This repo is active on .com')
    end
  end

  scenario 'repo uses a Service Hook' do
    WebMock.stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100")
           .to_return(status: 200, body: gh, headers: {})

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repo.id}/disable")
           .to_return(status: 200, body: '', headers: {})

    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    service = instance_double(Services::Repository::Disable)
    response = double
    allow(service).to receive(:call).and_return(response)
    allow(response).to receive(:success?).and_return(true)

    visit "/repositories/#{repo.id}"

    within(:css, '.activation-container') do
      expect(page).to have_text('enabled')

      find_button('Disable').trigger('click')
    end

    expect(page).to have_text('Disabled travis-pro/travis-admin')

    within(:css, '.gh-integration-container') do
      expect(page).to have_text('This repo uses a Service Hook')

      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text('That hook seems legit.')
  end
end
