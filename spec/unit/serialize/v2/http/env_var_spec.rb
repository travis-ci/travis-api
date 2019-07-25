describe Travis::Api::Serialize::V2::Http::EnvVar do
  let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: true) }
  let(:data) { described_class.new(env_var) }

  it 'returns value' do
    data.as_json['env_var'][:value].should == 'bar'
  end

  describe 'private' do
    let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: false) }

    it "doesn't return the value" do
      data.to_json.should_not include('bar')
      data.as_json['env_var']['value'].should be_nil
      data.as_json['env_var'][:value].should be_nil
    end
  end

  describe 'defined branch' do
    let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: false, branch: 'foo') }

    it "is set to foo" do
      data.as_json['env_var'][:branch].should == 'foo'
    end
  end
  
  describe 'undefined branch' do
    let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: false) }

    it "is set to null" do
      data.as_json['env_var'][:branch].should == nil
    end
  end
end
