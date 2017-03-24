module Travis::Model::EnvHelpers
  def obfuscate_env(vars)
    vars = [vars] unless vars.is_a?(Array)
    vars.compact.map do |var|
      repository.key.secure.decrypt(var) do |decrypted|
        next unless decrypted
        if decrypted.include?('=')
          "#{decrypted.to_s.split('=').first}=[secure]"
        else
          '[secure]'
        end
      end
    end
  end
end
