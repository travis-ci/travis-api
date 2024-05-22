describe Travis::API::V3::Models::Fingerprint do
  let(:klass_without_implementation) do
    Class.new do
      include Travis::API::V3::Models::Fingerprint
    end
  end
  let(:klass_with_nil_source) do
    Class.new do
      include Travis::API::V3::Models::Fingerprint
      def fingerprint_source
        nil
      end
    end
  end
  let(:klass_with_source) do
    Class.new do
      include Travis::API::V3::Models::Fingerprint
      def fingerprint_source
        OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem
      end
    end
  end

  let (:private_key_eddsa) {
"-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBQXfKTsmUKEONVc2i974UqTzI+Jci36WMfk/BnsWbU1gAAAJgPwlTaD8JU
2gAAAAtzc2gtZWQyNTUxOQAAACBQXfKTsmUKEONVc2i974UqTzI+Jci36WMfk/BnsWbU1g
AAAEBKnjD7h7IMc9yK5y+8yddm7Lze3vvP7+4OIbsYJ83raFBd8pOyZQoQ41VzaL3vhSpP
Mj4lyLfpYx+T8GexZtTWAAAAEmJnQExBUFRPUC1ISTQ5Q0hOTgECAw==
-----END OPENSSH PRIVATE KEY-----"
  }

  it 'must define fingerprint source' do
    instance = klass_without_implementation.new
    expect { instance.fingerprint }.to raise_error(NotImplementedError)
  end

  it 'returns nil when source is nil' do
    instance = klass_with_nil_source.new
    expect(instance.fingerprint).to be_nil
  end

  it 'returns fingerprint when source is a private key' do
    instance = klass_with_source.new
    expect(instance.fingerprint).to eq described_class.calculate(instance.fingerprint_source)
  end

  it 'calculates fingerprint from private key' do
    key = OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY)
    expect(described_class.calculate(key.to_pem)).to eq "57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40"
  end

  it 'calculates fingerprint from ed25519 private key' do
    expect(described_class.calculate(private_key_eddsa)).to eq "80:4e:61:7a:e3:28:a2:c6:42:57:e3:42:e4:16:bd:de"
  end
end
