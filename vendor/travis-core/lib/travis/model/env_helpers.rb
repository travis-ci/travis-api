module Travis::Model::EnvHelpers
  def obfuscate_env(vars)
    vars = [vars] unless vars.is_a?(Array)
    vars.compact.map do |var|
      repository.key.secure.decrypt(var) do |decrypted|
        Travis::Helpers.obfuscate_env_vars(decrypted)
      end
    end
  end
end
