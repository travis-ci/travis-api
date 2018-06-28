describe Travis::API::V3::Models::Build do
  let(:build) { Factory(:build, state: nil) }
  subject { Travis::API::V3::Models::Build.find_by_id(build.id) }

  example { expect(subject.state).to eq 'created' }

  describe 'casting sender to V3 model' do
    let(:sender) { Factory(:user) }

    before do
      subject.update_attributes(sender_type: 'User', sender_id: sender.id)
    end

    it 'always returns a V3 namespaced sender instance' do
      expect(subject.created_by).to be_a Travis::API::V3::Models::User
    end
  end
end
