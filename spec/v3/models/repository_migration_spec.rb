describe Travis::API::V3::Models::RepositoryMigration do
  let(:repository) { Factory(:repository) }

  subject { Travis::API::V3::Models::RepositoryMigration.new(repository) }

  before do
    Travis::Features.stubs(:feature_active?).with(:multi_os).returns(true)
    Travis::Features.stubs(:feature_active?).with(:dist_group_expansion).returns(true)
  end

  context 'when migration is enabled globally' do
    before { Travis::Features.expects(:feature_active?).with(:allow_merge_globally).returns(true) }

    context 'when migration is enabled for owner' do
      before { Travis::Features.expects(:owner_active?).with(:allow_migration, repository.owner).returns(true) }

      it 'migrates repository' do
        request = stub_request(:post, "#{Travis.config.merge.api_url}/api/repo/by_github_id/#{subject.repository.id}/migrate")
        subject.migrate!
        expect(request).to have_been_requested
      end
    end

    context 'when migration is disabled for owner' do
      before { Travis::Features.expects(:owner_active?).with(:allow_migration, repository.owner).returns(false) }

      it 'raises error' do
        expect { subject.migrate! }.to raise_error(Travis::API::V3::Models::RepositoryMigration::MigrationDisabledError)
      end
    end
  end

  context 'when migration is disabled globally' do
    before { Travis::Features.expects(:feature_active?).with(:allow_merge_globally).returns(false) }

    it 'raises error' do
      expect { subject.migrate! }.to raise_error(Travis::API::V3::Models::RepositoryMigration::MigrationDisabledError)
    end
  end
end
