require 'rails_helper'

RSpec.feature 'Enable a Repository', js: true, type: :feature do
  let!(:user)       { create(:user) }
  let!(:repository) { create(:inactive_repository, owner: user) }

  scenario 'User enables a repository' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repository.id}/enable").
      with(headers: {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(status: 200, body: '', headers: {})

    find_button('Enable').trigger('click')

    expect(page).to have_text("Enabled #{repository.slug}")
  end
end
