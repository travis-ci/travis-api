require 'rails_helper'

RSpec.feature "Sync with GitHub for a single user", :js => true, :type => :feature do
  let!(:user) { create(:user) }

  scenario "Syncing a user" do
    allow_any_instance_of(UsersController).to receive(:builds_provided_for).and_return(1)

    visit "/user/#{user.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/user/#{user.id}/sync").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => "", :headers => {})

    find_button('Sync').trigger('click')

    expect(page).to have_text("Triggered sync with GitHub.")
  end
end

RSpec.feature "Sync with GitHub for all users in an organization", :js => true, :type => :feature do
  let!(:katrin) { create(:user, login: 'lisbethmarianne') }
  let!(:aly) { create(:user, login: 'sinthetix') }
  let!(:organization) { create(:organization, users: [katrin, aly]) }

  scenario "Syncing several users" do
    allow_any_instance_of(OrganizationsController).to receive(:builds_provided_for).and_return(1)

    visit "/organization/#{organization.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/user/#{katrin.id}/sync").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => "", :headers => {})

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/user/#{aly.id}/sync").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => "", :headers => {})

    find_button('Sync all').trigger('click')

    expect(page).to have_text("Triggered sync with GitHub for lisbethmarianne, sinthetix.")
  end
end
