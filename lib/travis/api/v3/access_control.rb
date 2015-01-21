module Travis::API::V3
  module AccessControl
    REGISTER = {}

    def self.new(env)
      type, payload  = env['HTTP_AUTHORIZATION'.freeze].to_s.split(" ", 2)
      payload      &&= payload.unpack(?m.freeze).first if type == 'basic'.freeze
      payload      &&= type == 'token'.freeze ? payload.gsub(/^"(.+)"$/, '\1'.freeze) : payload.split(?:.freeze)
      modes          = REGISTER.fetch(type, [])
      access_control = modes.inject(nil) { |current, mode| current || mode.for_request(type, payload, env) }
      raise WrongCredentials unless access_control
      access_control
    end
  end
end
