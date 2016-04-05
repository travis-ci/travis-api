module Travis::API::V3
  module Models::Overview
    Branches = Struct.new(:branches)
    BuildDuration = Struct.new(:build_duration)
    EventType = Struct.new(:event_type)
    RecentBuildHistory = Struct.new(:recent_build_history)
    Streak = Struct.new(:streak)
  end
end
