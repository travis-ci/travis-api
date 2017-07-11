module Travis::API::V3
  module Models::Fingerprint
    def fingerprint
      return unless fingerprint_source
      calculate(fingerprint_source)
    end

    def fingerprint_source
      raise NotImplementedError
    end

    def calculate(source)
      rsa_key = OpenSSL::PKey::RSA.new(source)
      public_ssh_rsa = "\x00\x00\x00\x07ssh-rsa" + rsa_key.e.to_s(0) + rsa_key.n.to_s(0)
      OpenSSL::Digest::MD5.new(public_ssh_rsa).hexdigest.scan(/../).join(':')
    end

    module_function :calculate
  end
end
