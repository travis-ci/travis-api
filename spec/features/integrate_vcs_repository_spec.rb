require 'rails_helper'
require 'shared/vcs'
require 'shared/response_stubs/vcs_responses'

RSpec.feature 'Integrate VCS Repository', js: true, type: :feature do
  include_context 'vcs'
  include_context 'vcs_responses'

  let!(:integrated_repo) { create(:repo_with_users, active: true, managed_by_installation_at: Time.current) }
  let!(:repo) { create(:repo_with_users, owner_type: 'User', name: 'travis', active: true) }
  let!(:user) { repo.owner }

  before { allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([]) }

  scenario 'repo uses a VCS App Installation' do
    visit "/repositories/#{integrated_repo.id}"

    within(:css, '.vcs-integration-container') do
      expect(page).to have_text('This repo uses a VCS App Installation')
    end

    within(:css, '.activation-container') do
      expect(page).to have_text('This repo is active on .com')
    end
  end

  scenario 'repo uses a Service Hook' do
    stub_request(:get, "#{url}/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: vcs_response, headers: {})

    stub_request(:post, "#{url}/repo/#{repo.id}/disable")
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

    expect(page).to have_text('Disabled travis-pro/travis')

    within(:css, '.vcs-integration-container') do
      expect(page).to have_text('This repo uses a Service Hook')

      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text('That hook seems legit.')
  end
end
