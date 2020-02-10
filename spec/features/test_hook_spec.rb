require 'rails_helper'
require 'shared/vcs'

RSpec.feature 'Check Hook', js: true, type: :feature do
  include_context 'vcs'

  let!(:user)       { create(:user) }
  let!(:repository) { create(:repository, active: true, name: 'travis') }
  let!(:permission) { create(:permission, user: user, repository: repository, admin: true) }

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  end

  scenario 'Hook is legit' do
    stub_request(:post, "#{url}/repos/#{repository.id}/hook/test")
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: 200, body: '', headers: {})

    visit "/repositories/#{repository.id}"

    find_button('Test hook').trigger('click')

    expect(page).to have_text('Test hook fired.')
  end
end
