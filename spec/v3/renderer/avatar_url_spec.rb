describe Travis::API::V3::Renderer::AvatarURL do
  let(:object) { Object.new }
  subject { Travis::API::V3::Renderer::AvatarURL.avatar_url(object) }

  describe 'without any useful information' do
    it { is_expected.to be_nil }
  end

  describe 'with valid avatar_url' do
    let(:object) { double('input', avatar_url: "http://foo") }
    it { is_expected.to eq "http://foo" }
  end

  describe 'with valid avatar_url' do
    let(:object) { double('input', gravatar_url: "http://foo") }
    it { is_expected.to eq "http://foo" }
  end

  describe 'with valid gravatar_id' do
    let(:object) { double('input', gravatar_id: "foo") }
    it { is_expected.to eq "https://0.gravatar.com/avatar/foo" }
  end

  describe 'with valid avatar_url and gravatar_id' do
    let(:object) { double('input', avatar_url: "http://foo", gravatar_id: "https://0.gravatar.com/avatar/foo") }
    it { is_expected.to eq "http://foo" }
  end

  describe 'with missing avatar_url and valid gravatar_id' do
    let(:object) { double('input', avatar_url: nil, gravatar_id: "foo") }
    it { is_expected.to eq "https://0.gravatar.com/avatar/foo" }
  end

  describe 'with email' do
    let(:object) { double('input', email: "foo") }
    it { is_expected.to eq "https://0.gravatar.com/avatar/acbd18db4cc2f85cedef654fccc4a4d8" }
  end

  describe 'with email and empty gravatar_id' do
    let(:object) { double('input', gravatar_id: "", email: "foo") }
    it { is_expected.to eq "https://0.gravatar.com/avatar/acbd18db4cc2f85cedef654fccc4a4d8" }
  end

  describe 'with missing email' do
    let(:object) { double('input', email: nil) }
    it { is_expected.to be_nil }
  end
end
