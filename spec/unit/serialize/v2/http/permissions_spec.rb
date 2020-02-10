describe Travis::Api::Serialize::V2::Http::Permissions do
  include Travis::Testing::Stubs

  let(:permissions) do
    [
      double(:repository_id => 1, :admin? => true, :pull? => false, :push? => false),
      double(:repository_id => 2, :admin? => false, :pull? => true, :push? => false),
      double(:repository_id => 3, :admin? => false, :pull? => false, :push? => true)
    ]
  end

  let(:data) { described_class.new(permissions).data }

  it 'permissions' do
    expect(data['permissions']).to eq([1, 2, 3])
  end

  it 'finds admin perms' do
    expect(data['admin']).to eq([1])
  end

  it 'finds pull perms' do
    expect(data['pull']).to eq([2])
  end

  it 'finds push perms' do
    expect(data['push']).to eq([3])
  end
end

