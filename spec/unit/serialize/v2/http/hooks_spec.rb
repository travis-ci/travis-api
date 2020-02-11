describe Travis::Api::Serialize::V2::Http::Hooks do
  include Travis::Testing::Stubs

  let(:data) {
    r = repository
    allow(r).to receive(:admin?).and_return(true)
    described_class.new([r]).data
  }

  it 'hooks' do
    expect(data['hooks']).to eq([
      {
        'id' => 1,
        'name' => 'minimal',
        'owner_name' => 'svenfuchs',
        'description' => 'the repo description',
        'active' => true,
        'private' => false,
        'admin' => true
      }
    ])
  end
end
