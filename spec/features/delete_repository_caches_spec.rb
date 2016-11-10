require 'rails_helper'

RSpec.feature 'Delete repository caches', js: true, type: :feature do
  let!(:repository)   { create(:repository) }

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

    expect(page).to have_text('Cache for branch PR.123 successfully deleted.')
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

    expect(page).to have_text('Caches for travis-pro/travis-admin successfully deleted.')
  end
end