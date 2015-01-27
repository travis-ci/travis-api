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

    def bool(value)
      return false if value == 'false'.freeze
      !!value
    end

    def user_condition(value)
      case value
      when String  then { login: value    }
      when Integer then { id:    value    }
      when ::User  then { id:    value.id }
      else raise WrongParams
      end
    end
  end
end
