require 'rails_helper'

RSpec.feature "Add logs to audit trial", :js => true, :type => :feature do
  let(:redis) { Travis::DataStores.redis }
  let!(:broadcast) { create(:broadcast, message: 'Some message text.') }

  before { redis.set("feature:resubscribe:disabled", 1) }

  scenario "Audit trail has a new entry after user disables a global feature" do
    visit "/features"
    find_button('disable_resubscribe').trigger('click')
    expect(page).to have_text("Feature resubscribe disabled.")

    find_link('audit_trail').trigger('click')
    expect(page).to have_text('Unknown user disabled feature resubscribe for everybody.')
  end

  scenario "Audit trail has a new entry after user hides a broadcast for everybody" do
    visit "/broadcasts"
    find_button('Hide').trigger('click')
    expect(page).to have_button("Display")
    expect(page).to have_no_button("Hide")

    find_link('audit_trail').trigger('click')
    expect(page).to have_text("Unknown user disabled a broadcast for everybody: \"Some message text.\".")
  end
end
