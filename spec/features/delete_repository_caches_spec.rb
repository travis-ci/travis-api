require 'rails_helper'

RSpec.feature 'Delete repository caches', js: true, type: :feature do
  let!(:repository)   { create(:repository, id: 1) }

  before {
    allow(Services::Repository::Caches::FindAll.new(repository)).to receive(:call).and_return(
          '[{:repository_id => 1, :size => 49415347, :slug => "slug1.tgz", :branch => "PR.123",
          :last_modified => "2016-11-09T17:03:22Z"}, {:repository_id => 1, :size => "49415785", :slug => "slug2.tgz",
          :branch => "test-branch", :last_modified => "2016-11-09T16:52:26Z"}]')
  }

  scenario 'User deletes a branch cache' do
    visit "/repositories/#{repository.id}#caches"

    click_on('Caches')

    WebMock.stub_request(:delete, "https://api-fake.travis-ci.com/repos/#{repository.id}/caches").
      with(:body => "{\"branch\":\"test-branch\"}",
           :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2',
                        'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => "", :headers => {})

    find_button('Delete').trigger('click')

    expect(page).to have_text('The PR.123 cache for travis-pro/travis-admin was successfully deleted.')
  end

  scenario 'User clicks delete all caches' do
    visit "/repositories/#{repository.id}#caches"

    click_on('Caches')

    WebMock.stub_request(:delete, "https://api-fake.travis-ci.com/repos/1/caches").
      with(:body => '{}',
           :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'2',
                        'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => "", :headers => {})

    find_button('Delete All').trigger('click')

    expect(page).to have_text('Caches for travis-pro/travis-admin were successfully deleted.')
  end
end