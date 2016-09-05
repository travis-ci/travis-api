require 'rails_helper'

RSpec.feature "Update Features", :js => true, :type => :feature do
  let!(:repository)   { create(:repository) }
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let(:redis)         { Travis::DataStores.redis }

  before { redis.sadd("feature:annotations:repositories", "#{repository.id}")
           redis.sadd("feature:cron:users", "#{user.id}")
           redis.sadd("feature:cron:organizations", "#{organization.id}") }

  scenario "Update features for a repository" do
    visit "/repository/#{repository.id}"
    click_on("Settings")

    expect(page.has_checked_field?("features_multi_os")).to be false
    expect(page.has_checked_field?("features_annotations")).to be true

    find("#features_multi_os").trigger('click')
    find("#features_annotations").trigger('click')
    find_button("update-features").trigger('click')

    expect(page).to have_text("Updated feature flags for travis-pro/travis-admin.")

    # rethink this (is not working without)
    click_on("Settings")
    expect(page.has_checked_field?("features_multi_os")).to be true
    expect(page.has_checked_field?("features_annotations")).to be false
  end

  scenario "Update features for a user" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/user/#{user.id}"
    click_on("Account")

    expect(page.has_checked_field?("features_cron")).to be true

    find("#features_cron").trigger('click')
    find_button("update-features").trigger('click')

    expect(page).to have_text("Updated feature flags for sinthetix.")

    # rethink this (is not working without)
    click_on("Account")
    expect(page.has_checked_field?("features_cron")).to be false
  end

  scenario "Update features for an organization" do
    allow(Travis::DataStores.topaz).to receive(:builds_provided_for)

    visit "/organization/#{organization.id}"
    click_on("Account")

    expect(page.has_checked_field?("features_cron")).to be true

    find("#features_cron").trigger('click')
    find_button("update-features").trigger('click')

    expect(page).to have_text("Updated feature flags for travis-pro.")

    # rethink this (is not working without)
    click_on("Account")
    expect(page.has_checked_field?("features_cron")).to be false
  end
end
