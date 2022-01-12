module Travis::API::V3
  class Models::V2Addon
    attr_reader :id, :name, :type, :current_usage, :recurring

    def initialize(attrs)
      @id = attrs.fetch('id')
      @name = attrs.fetch('name')
      @type = attrs.fetch('type')
      @current_usage = attrs['current_usage'] && Models::V2AddonUsage.new(attrs['current_usage'])
      @recurring = attrs['recurring']
    end
  end
end
