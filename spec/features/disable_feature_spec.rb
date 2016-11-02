require 'rails_helper'

RSpec.feature "Disable a Feature", js: true, type: :feature do
  let(:redis) { Travis::DataStores.redis }

  before { redis.set("feature:resubscribe:disabled", 1) }

  scenario "User disables a global feature" do
    visit "/features"

    find_button('disable_resubscribe').trigger('click')

    expect(page).to have_text("Feature resubscribe disabled.")
  end
end
