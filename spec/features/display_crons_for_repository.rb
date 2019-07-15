require 'rails_helper'

RSpec.feature 'Display Repository Crons', js: true, type: :feature do
  let!(:repo) { create(:repository) }
  fake_crons = [{'branch' => {'name' => 'master'},
                 'interval' => 'monthly',
                 'last_run' => '2019-05-21T15:27:14Z',
                 'next_run' => '2019-06-21T15:27:14Z',
                 'dont_run_if_recent_build_exists' => 'false',
                },
                {'branch' => {'name' => 'latest'},
                 'interval' => 'daily',
                 'last_run' => '2019-05-21T15:27:14Z',
                 'next_run' => '2019-05-22T15:27:14Z',
                 'dont_run_if_recent_build_exists' => 'true',
                }]

  scenario 'repository page contains crons list with two elements' do
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repo.slug}/crons").
        to_return(status: 200, body: fake_crons)
    visit "/repositories/#{repo.id}"
    expect(page).to have_text('Cron Jobs')
    expect(page).to_not have_text('There are no Cron Jobs set')
    expect(page.find_all('.cron-header').length).to eq(1)
    expect(page.find_all('.cron-item').length).to eq(2)
  end

  scenario 'repository page contains crons list with two elements' do
    WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repo.slug}/crons").
        to_return(status: 200, body: [])
    visit "/repositories/#{repo.id}"
    expect(page).to have_text('Cron Jobs')
    expect(page).to have_text('There are no Cron Jobs set')
    expect(page.find_all('.cron-header').length).to eq(0)
    expect(page.find_all('.cron-item').length).to eq(0)
  end
end