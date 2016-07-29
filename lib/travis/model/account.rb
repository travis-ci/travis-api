class Account
  class << self
    def from(record, attrs = {})
      new(record.attributes.merge(:type => record.class.name).merge(attrs))
    end
  end

  ATTR_NAMES = [:id, :type, :name, :login, :repos_count, :avatar_url]

  attr_accessor *ATTR_NAMES

  def initialize(attrs)
    attrs = attrs.symbolize_keys
    ATTR_NAMES.each do |name|
      self.send(:"#{name}=", attrs[name])
    end
  end

  def ==(other)
    id == other.id && type == other.type
  end
end
