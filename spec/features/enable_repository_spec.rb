require 'rails_helper'

RSpec.feature "Enable a Repository", :js => true, :type => :feature do
  let!(:user) { create(:user) }
  let!(:repository) { create(:repository, name: 'travis-ci', description: 'test', private: true, default_branch: 'master', owner: user, active: false) }

  scenario "User enables a repository" do
    name, password = ENV['ADMIN_NAME'], ENV['ADMIN_PASSWORD']
    page.driver.basic_authorize(name, password)

    visit "/repository/#{repository.id}"

    WebMock.stub_request(:post, "https://api-fake.travis-ci.com/repo/#{repository.id}/enable").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token', 'Content-Length'=>'0', 'Content-Type'=>'application/json', 'Travis-Api-Version'=>'3', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => "", :headers => {})

    click_link "Enable"

    expect(page).to have_text("Enabled #{repository.slug}")
  end
end
