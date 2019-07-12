require 'rails_helper'

RSpec.feature 'Enable a Repository', js: true, type: :feature do
  let!(:user)       { create(:user) }
  let!(:repository) { create(:inactive_repository, owner: user) }

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  end

  scenario 'User enables a repository' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repository.id}/enable").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    within(:css, '.active-container') do
      find_button('Enable').trigger('click')
    end

    expect(page).to have_text("Enabled #{repository.slug}")
  end
end
