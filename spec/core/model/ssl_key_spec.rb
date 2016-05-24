require 'spec_helper'

describe SslKey do
  include Support::ActiveRecord

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
    SSL_KEYS = {
      :public_key     => "-----BEGIN PUBLIC KEY-----\nMDwwDQYJKoZIhvcNAQEBBQADKwAwKAIhALlyZuHmCjZf8pGCUmqz1NESpeVMJoes\nWQblf1p2WhnZAgMBAAE=\n-----END PUBLIC KEY-----\n",
      :private_key    => "-----BEGIN RSA PRIVATE KEY-----\nMIGrAgEAAiEAuXJm4eYKNl/ykYJSarPU0RKl5Uwmh6xZBuV/WnZaGdkCAwEAAQIg\nVHk9Tjd4fW5VU1z25+4EyXQNnMvaJGr0vP/iG2xSRpECEQD0k/AbOvzsxT5KDXP9\nnsxNAhEAwhuFRSrB1ef6EIPEyLDZvQIRAMGkH4ZvvbD4uciHvj4fbEECEBAl0fRr\nFi0BW2A8VgaMD9ECEQCYSndvz+Vw6SnR9YqElWqc\n-----END RSA PRIVATE KEY-----\n",
      :public_base64  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAIQC5cmbh5go2X/KRglJqs9TREqXlTCaHrFkG5X9adloZ2Q==",
      :private_base64 => "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUdyQWdFQUFpRUF1\nWEptNGVZS05sL3lrWUpTYXJQVTBSS2w1VXdtaDZ4WkJ1Vi9XblphR2RrQ0F3\nRUFBUUlnClZIazlUamQ0Zlc1VlUxejI1KzRFeVhRTm5NdmFKR3IwdlAvaUcy\neFNScEVDRVFEMGsvQWJPdnpzeFQ1S0RYUDkKbnN4TkFoRUF3aHVGUlNyQjFl\nZjZFSVBFeUxEWnZRSVJBTUdrSDRadnZiRDR1Y2lIdmo0ZmJFRUNFQkFsMGZS\ncgpGaTBCVzJBOFZnYU1EOUVDRVFDWVNuZHZ6K1Z3NlNuUjlZcUVsV3FjCi0t\nLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg=="
    }

    let(:key) { SslKey.new(SSL_KEYS.slice(:private_key, :public_key)) }

    it 'generates the correct key format to export to github' do
      key.encoded_public_key.should == SSL_KEYS[:public_base64]
    end

    it 'encodes the private key properly for the build' do
      key.encoded_private_key.should == SSL_KEYS[:private_base64]
    end
  end
end
