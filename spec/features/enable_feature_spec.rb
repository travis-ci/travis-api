require 'rails_helper'

RSpec.feature 'Enable a Feature', js: true, type: :feature do
  let(:redis) { Travis::DataStores.redis }

  before { redis.set('feature:resubscribe:disabled', 0) }

  scenario 'User enables a global feature' do
    visit '/features'

    find_button('enable_resubscribe').trigger('click')

    expect(page).to have_text('Feature resubscribe enabled.')
  end
end
