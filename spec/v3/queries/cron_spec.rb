describe Travis::API::V3::Queries::Crons do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:existing_branch) { Travis::API::V3::Models::Branch.create(repository: repo, name: 'cron-test-existing', exists_on_github: true) }
  let(:non_existing_branch) { Travis::API::V3::Models::Branch.create(repository: repo, name: 'cron-test-non-existing', exists_on_github: false) }
  let(:query) { Travis::API::V3::Queries::Crons.new({}, 'Overview')
}

  describe "start all" do
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }

    it "starts crons on existing branches" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: existing_branch.id, interval: 'daily', disable_by_build: false)
      expect(query.start_all).to include(cron)

    end

    it "delete crons on branches not existing on GitHub" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: non_existing_branch.id, interval: 'daily', disable_by_build: false)
      expect(query.start_all).to_not include(cron)
      expect(Travis::API::V3::Models::Cron.where(id: cron.id).length).to equal(0)
    end
  end

end
