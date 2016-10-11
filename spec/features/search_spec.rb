require 'rails_helper'

RSpec.feature 'Search', :js => true, :type => :feature do
  let!(:user)         { create(:user, login: 'lisbethmarianne', name: 'Katrin', email: 'katrin@example.com') }
  let!(:organization) { create(:organization, login: 'rubymonstas', name: 'Ruby Monstas') }
  let!(:repository)   { create(:repository, owner_name: user.login, name: 'test1') }
  let!(:repository2)  { create(:repository, owner_name: organization.login, name: 'test1') }
  let!(:commit)       { create(:commit, committer_name: 'Katrin', committer_email: 'katrin@example.com', author_name: 'Katrin', author_email: 'katrin@example.com') }
  let!(:build)        { create(:build, commit: commit, config: {}) }
  let!(:job)          { create(:job, commit: commit, config: {}) }

  scenario "User searches for user login 'lisbethmarianne' and gets redirected to the user view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/"
    fill_in('q', :with => 'lisbethmarianne')
    find_button('search-submit').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for organization login 'rubymonstas' and gets redirected to the organization view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/"
    fill_in('q', :with => 'rubymonstas')
    find_button('search-submit').trigger('click')

    expect(page).to have_text('Organization - Ruby Monstas (rubymonstas)')
  end

  scenario "User searches for repository name 'test1' and gets the search results page with 2 results" do
    visit "/"
    fill_in('q', :with => 'test1')
    find_button('search-submit').trigger('click')

    expect(page).to have_text('Repository rubymonstas/test1')
    expect(page).to have_text('Repository lisbethmarianne/test1')
  end

  scenario "User searches for something that doesn't exist and gets the search results page with no results" do
    visit "/"
    fill_in('q', :with => 'hello')
    find_button('search-submit').trigger('click')

    expect(page).to have_text('No results.')
  end

  scenario "User searches for 'help' and gets the search help page" do
    visit "/"

    fill_in('q', :with => 'help')
    find_button('search-submit').trigger('click')

    expect(page).to have_text('Search Help')
  end

  scenario "User searches for Committer Name via button on Build view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/builds/#{build.id}"
    find_button('search-committer_name').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Committer Email via button on Build view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/builds/#{build.id}"
    find_button('search-committer_email').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Author Name via button on Build view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/builds/#{build.id}"
    find_button('search-author_name').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Author Email via button on Build view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/builds/#{build.id}"
    find_button('search-author_email').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Committer Name via button on Job view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/jobs/#{job.id}"
    find_button('search-committer_name').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Committer Email via button on Job view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/jobs/#{job.id}"
    find_button('search-committer_email').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Author Name via button on Job view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/jobs/#{job.id}"
    find_button('search-author_name').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end

  scenario "User searches for Author Email via button on Job view" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/jobs/#{job.id}"
    find_button('search-author_email').trigger('click')

    expect(page).to have_text('User - Katrin (lisbethmarianne)')
  end
end
