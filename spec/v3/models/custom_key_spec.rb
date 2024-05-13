describe Travis::API::V3::Models::CustomKey do
  let(:user) { FactoryBot.create(:user) }
  let(:owner_type) { 'User' }
  let(:owner_id) { user.id }
  let(:name) { 'TEST_KEY' }
  let(:added_by) { user.id }
  let(:private_key) { OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem }

  let(:private_key_ecdsa) {
"-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAaAAAABNlY2RzYS
1zaGEyLW5pc3RwMjU2AAAACG5pc3RwMjU2AAAAQQTbEktrwU/QoCLiy+EsVKPqHBFFkGHA
iZ72G3u9ZUs09KMiQkqDPMC9mHNLJAG6jBCfZeCtaIcWDYmG+jHsg1WTAAAAsMOIeDTDiH
g0AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNsSS2vBT9CgIuLL
4SxUo+ocEUWQYcCJnvYbe71lSzT0oyJCSoM8wL2Yc0skAbqMEJ9l4K1ohxYNiYb6MeyDVZ
MAAAAgd/BbvXfNx31PEc2rVvFKTh6eoPbkEgW/C0tuzDBv5y4AAAASYmdATEFQVE9QLUhJ
NDlDSE5OAQIDBAUG
-----END OPENSSH PRIVATE KEY-----"
  }

  subject { Travis::API::V3::Models::CustomKey.new }

  it 'must save valid private key' do
    key = subject.save_key!(owner_type, owner_id, name, '', private_key, added_by)

    expect(key.name).to eq(name)
    expect(key.fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40')
  end

  it 'must save ecdsa valid private key' do
    key = subject.save_key!(owner_type, owner_id, name, '', private_key_ecdsa, added_by)

    expect(key.name).to eq(name)
    expect(key.fingerprint).to eq('ca:b4:4d:ee:34:27:8b:6b:18:52:69:0a:5b:c0:75:16')
  end

  it 'must not save invalid private key' do
    key = subject.save_key!(owner_type, owner_id, name, '', 'INVALID', added_by)

    expect(key.errors.messages[:private_key]).to eq(['invalid_pem'])
  end
end
