require 'rails_helper'

RSpec.feature 'Delete repository caches', js: true, type: :feature do
  let!(:repository) { create(:repository, id: 1) }

  before {
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  }

  scenario 'User deletes a branch cache' do
    # get caches
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: JSON.generate(caches: [{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}, {:repository_id => 1, :size => 49415785, :slug => "slug2.tgz",
          :branch => "test-branch", :last_modified => "2016-11-09T16:52:26Z"}]))

    # delete cache for branch 'test-branch'
    WebMock.stub_request(:delete, "https://api-fake.travis-ci.com/repo/#{repository.id}/caches?branch=test-branch").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: "")

    visit "/repositories/#{repository.id}/caches"

    # get new caches (cache for test-branch was deleted)
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: JSON.generate(caches: [{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}]))

    page.find('li', text: 'test-branch').find_button('Delete').trigger('click')

    expect(page).to have_text("The 'test-branch' cache for travis-pro/travis-admin was successfully deleted.")
  end

  scenario 'User clicks delete all caches' do
    # get caches
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: JSON.generate(caches: [{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}, {:repository_id => 1, :size => 49415785, :slug => "slug2.tgz",
          :branch => "test-branch", :last_modified => "2016-11-09T16:52:26Z"}]))

    # delete caches
    WebMock.stub_request(:delete, "https://api-fake.travis-ci.com/repo/#{repository.id}/caches").
      with(body:    {},
           headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: "")

    visit "/repositories/#{repository.id}/caches"

    # get new caches (cache for all branches deleted)
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repository.id}/caches").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: JSON.generate(caches: []))

    find_button('Delete All').trigger('click')

    expect(page).to have_text('Caches for travis-pro/travis-admin were successfully deleted.')

    click_on('Caches')

    expect(page).to have_text('No caches found for this repository.')
  end
end
