require 'rails_helper'

RSpec.feature "Update Settings", js: true, type: :feature do
  let!(:repository) { create(:repository) }

  scenario "Update one setting for a repository" do
    WebMock.stub_request(:patch, "https://api-fake.travis-ci.com/repo/#{repository.id}/setting/build_pushes").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'},
           body: {"setting.value": false}).to_return(:status => 200, :body => '', :headers => {})

    visit "/repositories/#{repository.id}"

    expect(page.has_checked_field?("settings_build_pushes")).to be true

    find("#settings_build_pushes").trigger('click')
    find_button("update-settings").trigger('click')

    expect(page).to have_text("Updated settings for travis-pro/travis-admin")
  end

  scenario "Update several settings for a repository" do
    WebMock.stub_request(:patch, "https://api-fake.travis-ci.com/repo/#{repository.id}/setting/build_pushes").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'},
           body: {"setting.value": false}).to_return(:status => 200, :body => '', :headers => {})

      WebMock.stub_request(:patch, "https://api-fake.travis-ci.com/repo/#{repository.id}/setting/maximum_number_of_builds").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'},
           body: {"setting.value": 1}).to_return(:status => 200, :body => '', :headers => {})

    visit "/repositories/#{repository.id}"

    expect(page.has_checked_field?("settings_build_pushes")).to be true
    expect(page).to have_field('settings_maximum_number_of_builds', with: '0')

    find("#settings_build_pushes").trigger('click')
    fill_in('settings_maximum_number_of_builds', :with => '1')
    find_button("update-settings").trigger('click')

    expect(page).to have_text("Updated settings for travis-pro/travis-admin")
  end
end
