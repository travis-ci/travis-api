describe Travis::Api::Serialize::V2::Http::Hooks do
  include Travis::Testing::Stubs

  let(:data) {
    r = repository
    r.stubs(:admin?).returns(true)
    described_class.new([r]).data
  }

  it 'hooks' do
    data['hooks'].should == [
      {
        'id' => 1,
        'name' => 'minimal',
        'owner_name' => 'svenfuchs',
        'description' => 'the repo description',
        'active' => true,
        'private' => false,
        'admin' => true
      }
    ]
  end
end
