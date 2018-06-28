class Account
  class << self
    def from(record, attrs = {})
      attrs = record.attributes.merge(attrs)
      attrs = attrs.merge(
        type: record.class.name,
        subscribed: record.subscribed?,
        education: education?(record)
      )
      new(attrs)
    end

    def education?(record)
      !!Travis::Github::Education.active?(record)
    end
  end

  ATTR_NAMES = [:id, :type, :name, :login, :repos_count, :avatar_url,
    :subscribed, :education]

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
