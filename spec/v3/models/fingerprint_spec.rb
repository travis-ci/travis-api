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
end
