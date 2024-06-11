describe Travis::API::V3::Models::CustomKey do
  let(:user) { FactoryBot.create(:user) }
  let(:owner_type) { 'User' }
  let(:owner_id) { user.id }
  let(:name) { 'TEST_KEY' }
  let(:added_by) { user.id }
  let(:private_key) { OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem }

  let(:ec_private_key) {"-----BEGIN EC PRIVATE KEY-----
MHcCAQEEICOoqfj+tlTuNsR2os/0xNBho2VcvrhACqLVczlw/3MPoAoGCCqGSM49
AwEHoUQDQgAE32uTS2qH6uuLLPR0zPP1wa1UVaPwk9fG9bqS+cnCaieS6cqPLca9
szwiqzF1idZ5lqqpCsg07+LJziMj6uT7aA==
-----END EC PRIVATE KEY-----"
  }

  let(:openssh_private_key) {"-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAArAAAABNlY2RzYS
1zaGEyLW5pc3RwNTIxAAAACG5pc3RwNTIxAAAAhQQALdavuM80eD0vC69PPvIx5+3VP2B/
R5I+7WaYWTTM/jyD/Tm9zjQxd6RtQTMX6LudWQu7BlObovRZHn/NwBsigtwBms+iWFD7/D
hvoDZ+exJffZZsotP0Gy70cuT+Rryit8afAtqOklLLHaTJRbKsq9o5a3oOBjlessxHKBk+
Le5bhfYAAAEQJ1OUWydTlFsAAAATZWNkc2Etc2hhMi1uaXN0cDUyMQAAAAhuaXN0cDUyMQ
AAAIUEAC3Wr7jPNHg9LwuvTz7yMeft1T9gf0eSPu1mmFk0zP48g/05vc40MXekbUEzF+i7
nVkLuwZTm6L0WR5/zcAbIoLcAZrPolhQ+/w4b6A2fnsSX32WbKLT9Bsu9HLk/ka8orfGnw
LajpJSyx2kyUWyrKvaOWt6DgY5XrLMRygZPi3uW4X2AAAAQXXzvQmgZV7gCF9e2S+2m2n1
ygt93K89KFFCRpdwRNFKBzHeNIGjyP3M3zoeasYxxcJ5DpFiqKZKqvL8VRUefk/2AAAAEm
JnQExBUFRPUC1ISTQ5Q0hOTgE=
-----END OPENSSH PRIVATE KEY-----"
  }

  let(:openssh_public_key) {"ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAt1q+4zzR4PS8Lr08+8jHn7dU/YH9Hkj7tZphZNMz+PIP9Ob3ONDF3pG1BMxfou51ZC7sGU5ui9Fkef83AGyKC3AGaz6JYUPv8OG+gNn57El99lmyi0/QbLvRy5P5GvKK3xp8C2o6SUssdpMlFsqyr2jlreg4GOV6yzEcoGT4t7luF9g== bg@LAPTOP-HI49CHNN"}

  let(:cosign_private_key) {"-----BEGIN ENCRYPTED SIGSTORE PRIVATE KEY-----
eyJrZGYiOnsibmFtZSI6InNjcnlwdCIsInBhcmFtcyI6eyJOIjo2NTUzNiwiciI6
OCwicCI6MX0sInNhbHQiOiJuWDVOZUdmaGhtaVRObGJidE91NGZneTM5UGQ2OXdU
UW5aMDFrSTJJMnZNPSJ9LCJjaXBoZXIiOnsibmFtZSI6Im5hY2wvc2VjcmV0Ym94
Iiwibm9uY2UiOiIyejNhNktnc1VHZEdHeDV6eTNCUEFCZ3hqNEF1QXNUMCJ9LCJj
aXBoZXJ0ZXh0IjoiaERLWkY4SVJxeDA1TWYyelpXZVBodHRCZENXTitoZVNreHox
a2t6YmhvdU1weWxwWXcyaExWSUxLcFZtSEJ0VG9vWU51RklYdWFwWTBXYVBxdXpx
eVd6RW9DMTJpUVhQMnZzRWd1QVo0a1dxZWJyTlFEamVEYnVvdSs4Rm96UnJMS2RX
VWdUaFFiNndsSzRnczAzNEtwaTB3UzlkWXE5WTkrUTVvLzJPeFNwWGljSmJjbGVM
QUsyUGNLcjdsYVZOclpFTWVKTklSWnkvZEE9PSJ9
-----END ENCRYPTED SIGSTORE PRIVATE KEY-----"}
  let(:cosign_public_key) {"-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+bhH9Msml4DB/GITW8yAluTrX2fJ
wRl5ulj8jfVioO/k8tT+kGXKps1qcKYgYbyfKKmeSAbaWkOcomC/DyL2nA==
-----END PUBLIC KEY-----"}

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

  it 'must save valid private ecdsa key' do
    key = subject.save_key!(owner_type, owner_id, name, '', ec_private_key, added_by)

    expect(key.name).to eq(name)
    expect(key.fingerprint).to eq('33:9b:75:af:4e:2b:bd:2e:31:e5:47:4a:23:e0:eb:d6')
  end

  it 'must save valid openssh key pair' do
    key = subject.save_key!(owner_type, owner_id, name, '', openssh_private_key, added_by, openssh_public_key)

    expect(key.name).to eq(name)
    expect(key.fingerprint).to eq('34:59:f8:66:3a:8c:21:ee:36:f8:60:ce:c9:12:de:f5')
  end

  it 'must save valid cosign key pair' do
    key = subject.save_key!(owner_type, owner_id, name, '', cosign_private_key, added_by, cosign_public_key)

    expect(key.name).to eq(name)
    expect(key.fingerprint).to eq('ec:27:1a:26:f6:d3:21:6a:b1:cd:08:37:70:41:b0:ec')
  end

  it 'must not save cosign key without pub' do
    key = subject.save_key!(owner_type, owner_id, name, '', cosign_private_key, added_by)

    expect(key.errors.messages[:private_key]).to eq(['invalid_pem'])
  end


end
