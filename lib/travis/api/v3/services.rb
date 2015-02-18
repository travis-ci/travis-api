module Travis::API::V3
  module Services
    extend ConstantResolver

    Organization  = Module.new { extend Services }
    Organizations = Module.new { extend Services }
    Repositories  = Module.new { extend Services }
    Repository    = Module.new { extend Services }
    Requests      = Module.new { extend Services }

    def result_type
      @resul_type ||= name[/[^:]+$/].underscore.to_sym
    end
  end
end
