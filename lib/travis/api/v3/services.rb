module Travis::API::V3
  module Services
    extend ConstantResolver

    Accounts      = Module.new { extend Services }
    Branch        = Module.new { extend Services }
    Branches      = Module.new { extend Services }
    Broadcast     = Module.new { extend Services }
    Broadcasts    = Module.new { extend Services }
    Build         = Module.new { extend Services }
    Builds        = Module.new { extend Services }
    Job           = Module.new { extend Services }
    Organization  = Module.new { extend Services }
    Organizations = Module.new { extend Services }
    Owner         = Module.new { extend Services }
    Repositories  = Module.new { extend Services }
    Repository    = Module.new { extend Services }
    Requests      = Module.new { extend Services }
    User          = Module.new { extend Services }

    def result_type
      @result_type ||= name[/[^:]+$/].underscore.to_sym
    end
  end
end
