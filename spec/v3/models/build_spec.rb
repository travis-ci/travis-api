describe Travis::API::V3::Models::Build do
  let(:build) { Factory(:build, state: nil) }
  subject { Travis::API::V3::Models::Build.find_by_id(build.id).state }

  it { should eq 'created' }
end
