describe Travis::API::V3::ArtifactManagerClient do
  let(:client) { described_class.new(user_id) }
  let(:url) { 'https://artifact-manager.travis-ci.com' }
  let(:user_id) { rand(999) }
  let(:auth_key) { 'super_secret' }

  before do
    Travis.config.artifact_manager.url = url
    Travis.config.artifact_manager.auth_key = auth_key
  end

  describe '#delete_images' do
    let(:image_ids) { [1, 2, 3] }
    subject { client.delete_images(image_ids) }

    it 'sends a DELETE request to the artifact manager' do
      stub_request(:delete, "#{url}/images")
        .with(body: { image_ids: image_ids }.to_json, headers: { 'X-Travis-User-Id' => user_id.to_s })
        .to_return(status: 200, body: { images: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      subject
    end

    it 'raises an error if the request fails' do
      stub_request(:delete, "#{url}/images")
        .with(body: { image_ids: image_ids }.to_json, headers: { 'X-Travis-User-Id' => user_id.to_s })
        .to_return(status: 400, body: { error: 'Bad Request' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { subject }.to raise_error(Travis::API::V3::ClientError, 'Bad Request')
    end
  end
end
