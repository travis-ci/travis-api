require 'rails_helper'

RSpec.feature 'Delete repository caches', js: true, type: :feature do
  let!(:repository) { create(:repository, id: 1) }

  scenario 'User deletes a branch cache' do
    # get caches
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2'}).
      to_return(status: 200, body: JSON.generate(caches: [{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}, {:repository_id => 1, :size => "49415785", :slug => "slug2.tgz",
          :branch => "test-branch", :last_modified => "2016-11-09T16:52:26Z"}]))

    visit "/repositories/#{repository.id}#caches"

    page.find('li', text: 'test-branch').click_button('Delete')

    # delete cache for branch 'test-branch'
    WebMock.stub_request(:delete, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(body: "{\"branch\": \"test-branch\"}",
           headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2'}).
      to_return(status: 200, body: "")

    # get new caches (cache for test-branch was deleted)
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2'}).
      to_return(status: 200, body: JSON.generate(caches: [{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}]))

    expect(page).to have_text('The test-branch cache for travis-pro/travis-admin was successfully deleted.')
  end

  scenario 'User clicks delete all caches' do
    # get caches
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2'}).
      to_return(status: 200, body: JSON.generate(caches: [{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}, {:repository_id => 1, :size => "49415785", :slug => "slug2.tgz",
          :branch => "test-branch", :last_modified => "2016-11-09T16:52:26Z"}]))

    visit "/repositories/#{repository.id}#caches"

    find_button('Delete All').trigger('click')

    # delete caches
    WebMock.stub_request(:delete, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(body:    {},
           headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2'}).
      to_return(status: 200, body: "")

     # get new caches (cache for all branches deleted)
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2'}).
      to_return(status: 200, body: JSON.generate(caches: []))

    expect(page).to have_text('Caches for travis-pro/travis-admin were successfully deleted.')

    # Extra click necessary (?!)
    click_on('Caches')
    expect(page).to have_text('No caches found for this repository.')
  end
end
