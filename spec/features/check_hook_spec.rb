require 'rails_helper'

RSpec.feature 'Check Hook', js: true, type: :feature do
  let!(:user)       { create(:user) }
  let!(:repository) { create(:repository, active: true) }
  let!(:permission) { create(:permission, user: user, repository: repository, admin: true) }

  let(:gh) {
    [{
      "name"=>"travis",
      "active"=>true,
      "events"=>["pull_request", "push"],
      "config"=>{"domain"=>"notify.fake.travis-ci.com"}
    }]
  }

  let(:gh_not_active) {
    [{
      "name"=>"travis",
      "active"=>false,
      "events"=>["pull_request", "push"],
      "config"=>{"domain"=>"notify.fake.travis-ci.com"}
    }]
  }

  let(:gh_pr_missing) {
    [{
      "name"=>"travis",
      "active"=>true,
      "events"=>["push"],
      "config"=>{"domain"=>"notify.fake.travis-ci.com"},
      "_links"=>{"self"=>{"href"=>"https://api.github.com/repos/#{repository.slug}/hooks/8993326"}}
    }]
  }

  let(:gh_push_missing) {
    [{
      "name"=>"travis",
      "active"=>true,
      "events"=>["pull_request"],
      "config"=>{"domain"=>"notify.fake.travis-ci.com"},
      "_links"=>{"self"=>{"href"=>"https://api.github.com/repos/#{repository.slug}/hooks/8993326"}}
    }]
  }

  let(:gh_different_domain) {
    [{
      "name"=>"travis",
      "active"=>true,
      "events"=>["pull_request", "push"],
      "config"=>{"domain"=>"notify.fake2.travis-ci.com"},
      "_links"=>{"self"=>{"href"=>"https://api.github.com/repos/#{repository.slug}/hooks/8993326"}}
    }]
  }

  before {
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
  }

  scenario 'Hook is legit' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: gh, headers: {})

    find_button('Check Hook').trigger('click')

    expect(page).to have_text('That hook seems legit.')
  end

  scenario 'Hook is not active on GitHub' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: gh_not_active, headers: {})

    find_button('Check Hook').trigger('click')

    expect(page).to have_text("#{repository.slug} is marked active in our database but the GitHub hook is disabled. What should we do about it?")
    expect(page).to have_button('Enable')
    expect(page).to have_button('Disable')
  end

  scenario 'Event pull_request is missing' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: gh_pr_missing, headers: {})

    find_button('Check Hook').trigger('click')

    expect(page).to have_text("The GitHub hook for #{repository.slug} is not listening to pull request events. What should we do about it?")

    WebMock.stub_request(:patch, "https://api.github.com/repos/#{repository.slug}/hooks/8993326").
      with(:body => "{\"add_events\":[\"pull_request\"]}")

    find_button('Fix it').trigger('click')

    expect(page).to have_text("Added pull request event to #{repository.slug}.")
  end

  scenario 'Event push is missing' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: gh_push_missing, headers: {})

    find_button('Check Hook').trigger('click')

    expect(page).to have_text("The GitHub hook for #{repository.slug} is not listening to push events. What should we do about it?")

    WebMock.stub_request(:patch, "https://api.github.com/repos/#{repository.slug}/hooks/8993326").
      with(:body => "{\"add_events\":[\"push\"]}")

    find_button('Fix it').trigger('click')

    expect(page).to have_text("Added push event to #{repository.slug}.")
  end

  scenario 'Different Domain' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: gh_different_domain, headers: {})

    find_button('Check Hook').trigger('click')

    expect(page).to have_text("The GitHub hook for #{repository.slug} is sending notifications to https://notify.fake2.travis-ci.com, but should be sending them to https://notify.fake.travis-ci.com. What should we do about it?")

    WebMock.stub_request(:patch, "https://api.github.com/repos/travis-pro/travis-admin/hooks/8993326").
      with(:body => "{\"config\":{\"domain\":\"https://notify.fake.travis-ci.com\"}}")

    find_button('Fix it').trigger('click')

    expect(page).to have_text('Set notification target to https://notify.fake.travis-ci.com.')
  end

  scenario 'No hook on GitHub' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: [], headers: {})

    find_button('Check Hook').trigger('click')

    expect(page).to have_text('No hook found on GitHub.')
  end
end
