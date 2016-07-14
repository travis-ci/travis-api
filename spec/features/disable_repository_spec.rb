require 'rails_helper'

RSpec.feature "Disable a Repository", :js => true, :type => :feature do
  let!(:user) { create(:user) }
  let!(:repository) { create(:repository, name: 'travis-pro', description: 'test', private: true, default_branch: 'master', owner: user, active: true) }

  scenario "User disables a repository" do
    visit "/repository/#{repository.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repository.id}/disable").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token', 'Content-Length'=>'0', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => "", :headers => {})

    find_link('Disable').trigger('click')

    expect(page).to have_text("Disabled #{repository.slug}")
  end
end
