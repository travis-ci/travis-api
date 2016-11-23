require 'rails_helper'

RSpec.feature "Update Features", js: true, type: :feature do
  let!(:repository)   { create(:repository) }
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let(:redis)         { Travis::DataStores.redis }

  before { redis.sadd('feature:annotations:repositories', "#{repository.id}")
           redis.sadd('feature:cron:users', "#{user.id}")
           redis.sadd('feature:cron:organizations', "#{organization.id}")
           allow(Travis::DataStores.topaz).to receive(:builds_provided_for)
           allow_any_instance_of(Services::Repository::Caches::FindAll).to receive(:call).and_return([]) }
  
  before(:each) { ::Features.reload }


  scenario 'Update features for a repository' do
    visit "/repositories/#{repository.id}"

    expect(page.has_checked_field?('features_multi_os')).to be false
    expect(page.has_checked_field?('features_annotations')).to be true

    find('#features_multi_os').trigger('click')
    find('#features_annotations').trigger('click')
    find_button('update-features').trigger('click')

    expect(page).to have_text('Updated feature flags for travis-pro/travis-admin.')

    click_on('Repository')

    expect(page.has_checked_field?('features_multi_os')).to be true
    expect(page.has_checked_field?('features_annotations')).to be false
  end

  scenario 'Update features for a user' do
    visit "/users/#{user.id}"

    expect(page.has_checked_field?('features_cron')).to be true

    find('#features_cron').trigger('click')
    find_button('update-features').trigger('click')

    expect(page).to have_text('Updated feature flags for travisbot.')
    expect(page.has_checked_field?('features_cron')).to be false
  end

  scenario 'Update features for an organization' do
    visit "/organizations/#{organization.id}"

    expect(page.has_checked_field?('features_cron')).to be true

    find('#features_cron').trigger('click')
    find_button('update-features').trigger('click')

    expect(page).to have_text('Updated feature flags for travis-pro.')
    expect(page.has_checked_field?('features_cron')).to be false
  end
end
