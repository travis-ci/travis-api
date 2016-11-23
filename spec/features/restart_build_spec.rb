require 'rails_helper'

RSpec.feature 'Restart a Build', js: true, type: :feature do
  let!(:repository) { create(:repository) }
  let!(:build)      { create(:failed_build, repository: repository, config: {}) }

  before {
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
  }

  scenario 'User restarts a build' do
    visit "/builds/#{build.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/restart").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#123 successfully restarted.')
  end

  scenario 'User restarts a build via builds tab in repository view' do
    visit "/repositories/#{repository.id}#builds"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/restart").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Restart').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#123 successfully restarted.')
    expect(page).to have_button('Restarted', disabled: true)
  end
end
