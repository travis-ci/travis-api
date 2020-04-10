require 'rails_helper'

RSpec.feature "Disable a Repository", js: true, type: :feature do
  let!(:user)       { create(:user) }
  let!(:repository) { create(:repository, name: 'travis-pro', description: 'test', private: true, default_branch: 'master', owner: user, active: true) }

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  end

  scenario 'User disables a repository' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repository.id}/deactivate").
      with(headers: {'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    within(:css, '.active-container') do
      find_button('Disable').trigger('click')
    end
    expect(page).to have_text("Disabled #{repository.slug}")
  end
end
