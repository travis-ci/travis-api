describe Travis::API::V3::Renderer::BuildBackup do
  let!(:build_backup) { FactoryBot.create(:build_backup) }
  let(:backup_model) { Travis::API::V3::Models::BuildBackup.find_by_id(build_backup.id) }
  let(:renderer) { Travis::API::V3::Renderer::BuildBackup.new(repo) }
  let(:content) { '123' }

  describe '.render' do
    subject { described_class.render(backup_model, :standard, accept: accept) }

    before { allow(backup_model).to receive(:content) { content } }

    context 'when accept is none' do
      let(:accept) { nil }

      it 'returns an object' do
        expect(subject).to eq(
          :@href => "/build_backup/#{build_backup.id}",
          :@representation => :standard,
          :@type => :build_backup,
          created_at: build_backup.created_at.iso8601,
          file_name: build_backup.file_name
        )
      end
    end

    context 'when accept is text/plain' do
      let(:accept) { 'text/plain' }

      it 'returns a string' do
        expect(subject).to eq(content)
      end
    end
  end
end
