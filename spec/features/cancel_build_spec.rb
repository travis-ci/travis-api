require 'rails_helper'

RSpec.feature 'Cancel a Build', js: true, type: :feature do
  let!(:repository) { create(:repository) }
  let!(:build)      { create(:started_build, repository: repository, config: {}) }

  before {
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
  }

  scenario 'User cancels a build' do
    visit "/builds/#{build.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/cancel").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#123 successfully canceled.')
  end

  scenario 'User cancels a build via builds tab in repository view' do
    visit "/repositories/#{repository.id}#builds"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/build/#{build.id}/cancel").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Cancel').trigger('click')

    expect(page).to have_text('Build travis-pro/travis-admin#123 successfully canceled.')
    expect(page).to have_button('Canceled', disabled: true)
  end
end
