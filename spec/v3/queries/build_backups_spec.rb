describe Travis::API::V3::Queries::BuildBackups do
  subject { described_class.new({ 'build_backups.repository_id' => repo.id }, 'BuildBackups') }

  describe '#all' do
    let(:repo) { FactoryBot.create(:repository) }
    let!(:build_backup) { FactoryBot.create(:build_backup, repository: repo) }

    it 'returns backups for repo' do
      backups = subject.all

      expect(backups.first.file_name).to eq(build_backup.file_name)
    end
  end
end
