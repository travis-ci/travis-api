require 'spec_helper'

describe Travis::Api::V2::Http::EnvVar do
  let(:env_var) { Repository::Settings::EnvVar.new(name: 'FOO', value: 'bar', public: true) }
  let(:data) { Travis::Api::V2::Http::EnvVar.new(env_var) }

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
end
