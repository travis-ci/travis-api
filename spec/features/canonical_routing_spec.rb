require 'rails_helper'

RSpec.feature 'Canonical routing', type: :routing do
  let!(:user)         { create(:user) }
  let!(:organization) { create(:organization) }
  let!(:build)        { create(:build) }
  let!(:job)          { create(:job) }
  let!(:repository)   { create(:repository) }

  describe 'Owner URLs' do
    scenario 'User-facing route /account redirects to back' do
      expect(get('/account')).to route_to('home#back')
    end

    scenario 'User-facing route /user redirects to /q?=user' do
      expect(get("/#{user.login}")).to route_to('unknown#canonical_route', other: "#{user.login}")
    end

    scenario 'User-facing route to /organization redirects to /q?=organization' do
      expect(get("/#{organization.login}")).to route_to('unknown#canonical_route', other: "#{organization.login}")
    end
  end

  describe 'Repository URLs' do
    scenario 'User-facing ../owner/repository route redirects to /repository/:id' do
      expect(get("/#{repository.owner_name}/#{repository.name}")).to route_to('unknown#repository',
                                                                              owner: "#{repository.owner_name}",
                                                                              repo: "#{repository.name}")
    end

    scenario 'User-facing ../owner/repository/* sub routes redirects to /repository/:id' do
      subroutes = %w[branches builds pull_requests settings requests caches]
      subroutes.each  do |subroute|
        expect(get("/#{repository.owner_name}/#{repository.name}/#{subroute}")).to route_to('unknown#repository',
                                                                                      owner: "#{repository.owner_name}",
                                                                                      repo: "#{repository.name}",
                                                                                      other: "#{subroute}")
      end
    end
  end

  describe 'Build URLs' do
    scenario 'User-facing ../builds/:id route redirects to /build/:id' do
      expect(get("/some_user/some_repo/builds/#{build.id}")).to route_to('unknown#build', id: "#{build.id}",
                                                                         owner: 'some_user', repo: 'some_repo')
    end
  end

  describe 'Job URLs' do
    scenario 'User-facing ../jobs/:id route redirects to /job/:id' do
      expect(get("/some_user/some_repo/jobs/#{job.id}")).to route_to('unknown#job', id: "#{job.id}",
                                                                     owner: 'some_user', repo: 'some_repo')
    end

    scenario 'User-facing ../jobs/:id/config route redirects to /job/:id' do
      expect(get("/some_user/some_repo/jobs/#{job.id}")).to route_to('unknown#job', id: "#{job.id}",
                                                                     owner: 'some_user', repo: 'some_repo')
    end
  end
end