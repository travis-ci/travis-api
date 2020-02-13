describe Travis::Api::Serialize::V2::Http::EnvVar do
  let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: true) }
  let(:data) { described_class.new(env_var) }

  it 'returns value' do
    expect(data.as_json['env_var'][:value]).to eq('bar')
  end

  describe 'private' do
    let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: false) }

    it "doesn't return the value" do
      expect(data.to_json).not_to include('bar')
      expect(data.as_json['env_var']['value']).to be_nil
      expect(data.as_json['env_var'][:value]).to be_nil
    end
  end

  describe 'defined branch' do
    let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: false, branch: 'foo') }

    it "is set to foo" do
      expect(data.as_json['env_var'][:branch]).to eq('foo')
    end
  end
  
  describe 'undefined branch' do
    let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: false) }

    it "is set to null" do
      expect(data.as_json['env_var'][:branch]).to eq(nil)
    end
  end
end
