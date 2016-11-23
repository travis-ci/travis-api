require 'rails_helper'

RSpec.feature 'Drop last build reference', js: true, type: :feature do
  let!(:repository) { create(:repository_with_last_build) }

  before {
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
  }

  scenario 'Drop last build reference for a repository' do
    allow_any_instance_of(ROTP::TOTP).to receive(:verify).with('123456').and_return(true)

    visit "/repositories/#{repository.id}"

    expect(page).to have_text('Last Build: #4 (passed at 2016-11-10 19:39:00 UTC)')

    find_button('Drop').trigger('click')
    fill_in('otp', with: '123456')
    find_button('Confirm').trigger('click')

    expect(page).to have_text('Last Build: No Build.')
    expect(page).to have_no_text('Last Build: #4 (passed at 2016-11-10 19:39:00 UTC)')
    expect(page).to have_no_button('Drop')
  end
end
