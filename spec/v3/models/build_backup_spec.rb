describe Travis::API::V3::Models::BuildBackup do
  let(:build_backup) { FactoryBot.create(:build_backup) }
  subject { Travis::API::V3::Models::BuildBackup.find_by_id(build_backup.id) }

  example { expect(subject.file_name).to be_present }
end
