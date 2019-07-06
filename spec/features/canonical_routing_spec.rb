require 'rails_helper'

RSpec.feature 'Canonical routing', type: :routing do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:build)        { create(:build) }
  let!(:job)          { create(:job) }

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

  describe 'Build URLs' do
    scenario 'User-facing ../builds/:id route redirects to /build/:id' do
      expect(get("/some_user/some_repo/builds/#{build.id}")).to route_to('builds#show', id: "#{build.id}",
                                                                         user: 'some_user', repo: 'some_repo')
    end
  end

  describe 'Job URLs' do
    scenario 'User-facing ../jobs/:id route redirects to /job/:id' do
      expect(get("/some_user/some_repo/jobs/#{job.id}")).to route_to('jobs#show', id: "#{job.id}",
                                                                     user: 'some_user', repo: 'some_repo')
    end

    scenario 'User-facing ../jobs/:id/config route redirects to /job/:id' do
      expect(get("/some_user/some_repo/jobs/#{job.id}")).to route_to('jobs#show', id: "#{job.id}",
                                                                     user: 'some_user', repo: 'some_repo')
    end
  end
end