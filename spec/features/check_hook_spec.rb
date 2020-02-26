require 'rails_helper'
require 'shared/vcs'
require 'shared/response_stubs/vcs_responses'

RSpec.feature 'Check hook', js: true, type: :feature do
  include_context 'vcs'
  include_context 'vcs_responses'

  let!(:user) { User.first || create(:user) }
  let!(:repo) { create(:repository, active: true, name: 'travis', owner: user) }
  let!(:permission) { create(:permission, user: user, repository: repo, admin: true) }

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  end

  scenario 'Hook is legit' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "#{url}/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: vcs_response, headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end
    expect(page).to have_text('That hook seems legit.')
  end

  scenario 'Hook is not active on VCS' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => 'Bearer fake-token', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: vcs_not_active, headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text("#{repo.slug} is marked active in our database but the VCS hook is disabled. What should we do about it?")
    expect(page).to have_button('Enable')
    expect(page).to have_button('Disable')
  end

  scenario 'Event pull_request is missing' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => 'Bearer fake-token', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: vcs_pr_missing, headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text("The VCS hook for #{repo.slug} is not listening to pull request events. What should we do about it?")

    stub_request(:put, "https://api-fake.travis-ci.com/repos/#{repo.id}/hook")
      .with(body: "{\"user_id\":#{user.id},\"add_events\":[\"pull_request\"]}",
            headers: { 'Authorization' => 'Bearer fake-token' })
      .to_return(status: 200, body: '', headers: {})

    find_button('Fix it').trigger('click')

    expect(page).to have_text("Added pull request event to #{repo.slug}.")
  end

  scenario 'Event push is missing' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => 'Bearer fake-token', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: vcs_push_missing, headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text("The VCS hook for #{repo.slug} is not listening to push events. What should we do about it?")

    stub_request(:put, "https://api-fake.travis-ci.com/repos/#{repo.id}/hook")
      .with(body: "{\"user_id\":#{user.id},\"add_events\":[\"push\"]}",
            headers: { 'Authorization' => 'Bearer fake-token' })
      .to_return(status: 200, body: '', headers: {})

    find_button('Fix it').trigger('click')

    expect(page).to have_text("Added push event to #{repo.slug}.")
  end

  scenario 'Different Domain' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => 'Bearer fake-token', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: vcs_different_domain, headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text("The VCS hook for #{repo.slug} is sending notifications to https://notify.fake2.travis-ci.com, but should be sending them to https://notify.fake.travis-ci.com. What should we do about it?")

    stub_request(:put, "https://api-fake.travis-ci.com/repos/#{repo.id}/hook")
      .with(body: "{\"user_id\":#{user.id},\"config\":{\"content_type\":\"json\",\"insecure_ssl\":\"0\",\"url\":\"https://example.com/\",\"domain\":\"https://notify.fake.travis-ci.com\"}}",
            headers: { 'Authorization' => 'Bearer fake-token' })

    find_button('Fix it').trigger('click')

    expect(page).to have_text('Set notification target to https://notify.fake.travis-ci.com.')
  end

  scenario 'No hook on VCS' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => 'Bearer fake-token', 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: '[]', headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text('No hook found on VCS.')
  end

  scenario 'User not found' do
    visit "/repositories/#{repo.id}"

    stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repo.id}/hooks?user_id=#{user.id}")
      .with(headers: { 'Authorization' => 'Bearer fake-token', 'Content-Type' => 'application/json' })
      .to_return(status: 404, body: '{"title":"Not Found","details":"User not found"}', headers: {})

    within(:css, '.active-container') do
      find_button('Check hook').trigger('click')
    end

    expect(page).to have_text('User not found')
  end
end
