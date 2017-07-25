module Travis::API::V3
  module Services
    extend ConstantResolver

    Accounts      = Module.new { extend Services }
    Active        = Module.new { extend Services }
    BetaFeature   = Module.new { extend Services }
    BetaFeatures  = Module.new { extend Services }
    Branch        = Module.new { extend Services }
    Branches      = Module.new { extend Services }
    Broadcast     = Module.new { extend Services }
    Broadcasts    = Module.new { extend Services }
    Build         = Module.new { extend Services }
    Builds        = Module.new { extend Services }
    Caches        = Module.new { extend Services }
    Cron          = Module.new { extend Services }
    Crons         = Module.new { extend Services }
    EnvVar        = Module.new { extend Services }
    EnvVars       = Module.new { extend Services }
    Job           = Module.new { extend Services }
    Jobs          = Module.new { extend Services }
    KeyPair       = Module.new { extend Services }
    Lint          = Module.new { extend Services }
    Log           = Module.new { extend Services }
    Organization  = Module.new { extend Services }
    Organizations = Module.new { extend Services }
    Owner         = Module.new { extend Services }
    Repositories  = Module.new { extend Services }
    Repository    = Module.new { extend Services }
    Request       = Module.new { extend Services }
    Requests      = Module.new { extend Services }
    SslKey        = Module.new { extend Services }
    Stages        = Module.new { extend Services }
    User          = Module.new { extend Services }
    UserSetting   = Module.new { extend Services }
    UserSettings  = Module.new { extend Services }

    def result_type
      @result_type ||= name[/[^:]+$/].underscore.to_sym
    end
  end
end
