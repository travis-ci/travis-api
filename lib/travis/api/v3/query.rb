module Travis::API::V3
  class Query
    def self.params(*list, prefix: nil)
      prefix ||= name[/[^:]+$/].underscore
      list.each { |e| class_eval("def #{e}; @params[\"#{prefix}.#{e}\".freeze]; end") }
    end

    attr_reader :params

    def initialize(params)
      @params = params
    end
  end
end
