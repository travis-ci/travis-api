describe Travis::API::V3::Queries::BuildBackup do
  subject { described_class.new({ 'build_backup.id' => build_backup.id }, 'BuildBackup') }

  describe '#find' do
    let(:repo) { FactoryBot.create(:repository) }
    let!(:build_backup) { FactoryBot.create(:build_backup, repository: repo) }
    let(:content) { '123' }

    let(:gcs_json_bucket_response) {
      %q{
        {"kind": "storage#bucket",
         "selfLink":  "https://www.googleapis.com/storage/v1/b/travis-cache-staging-org-gce",
          "name": "travis-cache-production-org-gce",
          "id": "travis-cache-staging-org-gce/25736446"
        }
      }
    }

    before do
      stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').
        to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /o\/#{build_backup.file_name}\?alt=media/).
        to_return(status: 200, body: content, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, "https://oauth2.googleapis.com/token").
        to_return(:status => 200, :body => "{}", :headers => {"Content-Type" => "application/json"})
      stub_request(:get,%r((.+))).with(
        headers: { 'Metadata-Flavor'=>'Google', 'User-Agent'=>'Ruby'}
      ).to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/fillme").
        to_return(:status => 200, :body => gcs_json_bucket_response, :headers => {"Content-Type" => "application/json"})
      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce/o/#{build_backup.file_name}").
        to_return(status: 200, body: gcs_json_bucket_response, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r((.+)travis-cache-production-org-gce\?alt=media)).
        to_return(status: 200, body: content, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r((.+)/o\/#{build_backup.file_name}\?alt=media/)).
        to_return(status: 200, body: content, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns backups for repo' do
      backup = subject.find

      expect(backup.file_name).to eq(build_backup.file_name)
      expect(backup.content).to eq(content)
    end
  end
end
