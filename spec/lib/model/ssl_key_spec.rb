describe SslKey do
  let(:key) { SslKey.new }

  before(:each) do
    key.generate_keys
  end

  it "is a SslKey" do
    expect(key).to be_a(SslKey)
  end

  describe "generate_keys" do
    it "generates the public key" do
      expect(key.public_key).to be_a(String)
    end

    it "generates the private key" do
      expect(key.private_key).to be_a(String)
    end

    it "does not generate a new public key if one already exists" do
      public_key = key.public_key
      key.generate_keys
      expect(key.public_key).to eq(public_key)
    end

    it "does not generate a new private key if one already exists" do
      private_key = key.private_key
      key.generate_keys
      expect(key.private_key).to eq(private_key)
    end
  end

  describe "generate_keys!" do
    it "generates a new public key even if one already exists" do
      public_key = key.public_key
      key.generate_keys!
      expect(key.public_key).not_to eq(public_key)
    end

    it "generates a new private key even if one already exists" do
      private_key = key.private_key
      key.generate_keys!
      expect(key.private_key).not_to eq(private_key)
    end
  end

  describe "encrypt" do
    it "encrypts something" do
      expect(key.encrypt("hello")).not_to be_nil
      expect(key.encrypt("hello")).not_to eql("hello")
    end

    it "is decryptable" do
      encrypted = key.encrypt("hello")
      expect(key.decrypt(encrypted)).to eql("hello")
    end
  end

  describe "decrypt" do
    it "decrypts something" do
      encrypted_string = key.encrypt("hello world")
      expect(key.decrypt(encrypted_string)).not_to be_nil
      expect(key.decrypt(encrypted_string)).not_to eql("hello")
    end
  end

  describe 'encoding' do
    let(:key) { SslKey.new(SSL_KEYS.slice(:private_key, :public_key)) }

    it 'generates the correct key format to export to github' do
      expect(key.encoded_public_key).to eq(SSL_KEYS[:public_base64])
    end

    it 'encodes the private key properly for the build' do
      expect(key.encoded_private_key).to eq(SSL_KEYS[:private_base64])
    end
  end
end
