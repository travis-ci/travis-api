require 'rails_helper'

RSpec.feature 'Drop last build reference', js: true, type: :feature do
  let!(:repository) do
    build = create(:build,
                   id: 123,
                   number: 4,
                   state: 'passed',
                   started_at: '2016-11-10 19:36:00 UTC',
                   finished_at: '2016-11-10 19:39:00 UTC',
                   duration: 180)

    repo = create(:repository,
                  last_build_id: 123,
                  last_build_number: '4',
                  last_build_started_at: '2016-11-10 19:36:00 UTC',
                  last_build_finished_at: '2016-11-10 19:39:00 UTC',
                  last_build_duration: 180,
                  last_build_state: 'passed')
    repo.builds << build
    repo
  end

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  end

  scenario 'Drop last build reference for a repository' do
    allow_any_instance_of(ROTP::TOTP).to receive(:verify).with('123456').and_return(true)

    visit "/repositories/#{repository.id}"

    expect(page).to have_text('#4 (passed at 2016-11-10 19:39:00 UTC)')

    find_button('Drop').trigger('click')
    fill_in('otp', with: '123456')
    find_button('Confirm').trigger('click')

    expect(page).to have_text('None.')
    expect(page).to have_no_text('#4 (passed at 2016-11-10 19:39:00 UTC)')
    expect(page).to have_no_button('Drop')
  end
end
