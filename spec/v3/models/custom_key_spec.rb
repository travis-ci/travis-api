describe Travis::API::V3::Models::CustomKey do
  let(:user) { FactoryBot.create(:user) }
  let(:owner_type) { 'User' }
  let(:owner_id) { user.id }
  let(:name) { 'TEST_KEY' }
  let(:added_by) { user.id }
  let(:private_key) { OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem }

  subject { Travis::API::V3::Models::CustomKey.new }

  it 'must save valid private key' do
    key = subject.save_key!(owner_type, owner_id, name, '', private_key, added_by)

    expect(key.name).to eq(name)
    expect(key.fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40')
  end

  it 'must not save invalid private key' do
    key = subject.save_key!(owner_type, owner_id, name, '', 'INVALID', added_by)

    expect(key.errors.messages[:private_key]).to eq(['invalid_pem'])
  end
end
