require 'rails_helper'

RSpec.feature "Disable a Repository", :js => true, :type => :feature do
  let!(:user) { create(:user) }
  let!(:repository) { create(:repository, name: 'travis-pro', description: 'test', private: true, default_branch: 'master', owner: user, active: true) }

  scenario "User disables a repository" do
    visit "/repository/#{repository.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repository.id}/disable").
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3'}).
      to_return(:status => 200, :body => "", :headers => {})

    find_link('Disable').trigger('click')

    expect(page).to have_text("Disabled #{repository.slug}")
  end
end
