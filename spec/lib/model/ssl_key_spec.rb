describe SslKey do
  let(:key) { SslKey.new }

  before(:each) do
    key.generate_keys
  end

  it "is a SslKey" do
    key.should be_a(SslKey)
  end

  describe "generate_keys" do
    it "generates the public key" do
      key.public_key.should be_a(String)
    end

    it "generates the private key" do
      key.private_key.should be_a(String)
    end

    it "does not generate a new public key if one already exists" do
      public_key = key.public_key
      key.generate_keys
      key.public_key.should == public_key
    end

    it "does not generate a new private key if one already exists" do
      private_key = key.private_key
      key.generate_keys
      key.private_key.should == private_key
    end
  end

  describe "generate_keys!" do
    it "generates a new public key even if one already exists" do
      public_key = key.public_key
      key.generate_keys!
      key.public_key.should_not == public_key
    end

    it "generates a new private key even if one already exists" do
      private_key = key.private_key
      key.generate_keys!
      key.private_key.should_not == private_key
    end
  end

  describe "encrypt" do
    it "encrypts something" do
      key.encrypt("hello").should_not be_nil
      key.encrypt("hello").should_not eql("hello")
    end

    it "is decryptable" do
      encrypted = key.encrypt("hello")
      key.decrypt(encrypted).should eql("hello")
    end
  end

  describe "decrypt" do
    it "decrypts something" do
      encrypted_string = key.encrypt("hello world")
      key.decrypt(encrypted_string).should_not be_nil
      key.decrypt(encrypted_string).should_not eql("hello")
    end
  end

  describe 'encoding' do
    let(:key) { SslKey.new(SSL_KEYS.slice(:private_key, :public_key)) }

    it 'generates the correct key format to export to github' do
      key.encoded_public_key.should == SSL_KEYS[:public_base64]
    end

    it 'encodes the private key properly for the build' do
      key.encoded_private_key.should == SSL_KEYS[:private_base64]
    end
  end
end
