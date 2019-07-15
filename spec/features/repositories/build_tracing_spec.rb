require 'rails_helper'

RSpec.feature 'Trace repo build', js: true, type: :feature do
  let!(:repository) { create(:repository, active: true) }

  before do
    allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([])
    allow_any_instance_of(Services::Repository::Crons).to receive(:call).and_return([])
  end

  context 'when ENV is not set' do
    scenario 'hides buttons' do
      visit "/repositories/#{repository.id}"

      within(:css, '.build-tracing-container') do
        expect(page).not_to have_text('View Traces')
        expect(page).not_to have_text('Disable')
        expect(page).not_to have_text('Enable')
      end
    end
  end

  context 'when ENV is set' do
    let(:redis) { Travis::DataStores.redis }
    before { ENV['BUILD_TRACE_GOOGLE_PROJECT'] = 'test' }

    scenario 'disabling tracing' do
      redis.sadd('trace.rollout.repos', repository.slug)
      visit "/repositories/#{repository.id}"

      within(:css, '.build-tracing-container') do
        expect(page).to have_text('enabled')
        find_button('Disable').trigger('click')
        expect(page).to have_text('disabled')
      end
    end

    scenario 'enabling tracing' do
      visit "/repositories/#{repository.id}"

      within(:css, '.build-tracing-container') do
        expect(page).to have_text('disabled')
        find_button('Enable').trigger('click')
        expect(page).to have_text('enabled')
      end
    end
  end
end
