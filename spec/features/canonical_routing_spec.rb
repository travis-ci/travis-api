require 'rails_helper'

RSpec.feature 'Canonical routing', type: :routing do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }

  describe 'Owner URLs' do
    scenario 'User-facing route /account redirects to not found' do
      expect(get('/account')).to route_to('home#not_found')
    end

    scenario 'User-facing route /user redirects to /q?=user' do
      expect(get("/#{user.login}")).to route_to('unknown#canonical_route', other: "#{user.login}")
    end

    scenario 'User-facing route to /organization redirects to /q?=organization' do
      expect(get("/#{organization.login}")).to route_to('unknown#canonical_route', other: "#{organization.login}")
    end
  end
end