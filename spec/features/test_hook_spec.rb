require 'rails_helper'

RSpec.feature 'Check Hook', js: true, type: :feature do
  let!(:user)       { create(:user) }
  let!(:repository) { create(:repository, active: true) }
  let!(:permission) { create(:permission, user: user, repository: repository, admin: true) }

  let(:gh) {
    [{
      "name"=>"travis",
      "active"=>true,
      "events"=>["pull_request", "push"],
      "config"=>{"domain"=>"notify.fake.travis-ci.com"},
      "_links"=>{"test"=>{"href"=>"https://api.github.com/repos/#{repository.slug}/hooks/8993326/test"}}
    }]
  }

  before {
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
  }

  scenario 'Hook is legit' do
    visit "/repositories/#{repository.id}"

    WebMock.stub_request(:get, "https://api.github.com/repos/#{repository.slug}/hooks?per_page=100").
      to_return(status: 200, body: gh, headers: {})

    WebMock.stub_request(:post, "https://api.github.com/repos/#{repository.slug}/hooks/8993326/test")

    find_button('Test Hook').trigger('click')

    expect(page).to have_text('Test hook fired.')
  end
end
