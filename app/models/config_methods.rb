require 'digest'

module ConfigMethods
  def config
    const = self.class.const_get(:Config)
    record = const.find_by(repository_id: repository_id)
    conf = record&.config || {}
    conf.deep_symbolize_keys!
  end

  def config=(config)
    const = self.class.const_get(:Config)
    find_or_initialize_config(const, config: JSON.dump(config))
  end

  def find_or_initialize_config(const, attrs)
    key = Digest::MD5.hexdigest(attrs[:config] || attrs[:yaml])
    record = const.find_by(repository_id: repository_id, key: key)
    record || const.new(attrs.merge(key: key, repository_id: repository_id))
  end
end
