require 'ssh_data'

class PrivateKey
  attr_reader :key
  def initialize(key)
    @key = key
  end

  def fingerprint
    rsa_key = OpenSSL::PKey::RSA.new(key)
    public_ssh_rsa = "\x00\x00\x00\x07ssh-rsa" + rsa_key.e.to_s(0) + rsa_key.n.to_s(0)
    OpenSSL::Digest::MD5.new(public_ssh_rsa).hexdigest.scan(/../).join(':')

    rescue => e
      handle_non_rsa
  end

  def handle_non_rsa
      nkey = ::SSHData::PrivateKey.parse_openssh(key)
      if nkey&.length > 0
        OpenSSL::Digest::MD5.new(nkey[0]&.public_key&.pk).hexdigest.scan(/../).join(':')
      end
  rescue
      nil
  end

  def inspect
    "<PrivateKey #{fingerprint}>"
  end
end
