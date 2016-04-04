module Travis::API::V3
  class Models::Overview

    def initialize(repo)
      @repo = repo
      @query = Queries::Overview.new({}, 'Overview')
    end

    def branches
      result = @query.branches(@repo)

      # order by branch name
      result.sort! { |a,b| a.branch <=> b.branch }

      passed = Hash.new(0)
      all    = Hash.new(0)

      result.each do |builds|
        passed[builds.branch_name] += builds.count.to_i if builds.state == "passed"
        all[builds.branch_name] += builds.count.to_i
      end

      data = {}

      # list default branch first
      default_branch = @repo.default_branch.name
      insert_guarded(data, passed, all, default_branch)
      passed.delete(default_branch)
      all.delete(default_branch)

      # after default branch all the other branches (in alphabetical order)
      all.each do |branch, sum|
        insert_guarded(data, passed, all, branch)
      end

      [{branches: data}]
    end

    def build_duration
      builds = @query.build_duration(@repo)
      data = []
      builds.each do |build|
        data.push ({
          "id"       => build.id,
          "number"   => build.number,
          "state"    => build.state,
          "duration" => build.duration
        })
      end
      [{build_duration: data}]
    end

    def event_type
      builds = @query.event_type(@repo)

      hash = Hash.new { |hash, key| hash[key] = Hash.new(0) }

      builds.each do |key, value|
        event_type = key[0]
        state      = key[1]
        hash[event_type][state] = value
      end

      [{event_type: hash}]
    end

    def recent_build_history
      builds = @query.recent_build_history(@repo)

      hash = Hash.new { |hash, key| hash[key] = Hash.new(0) }

      builds.each {|key, value|
        created_at = key[0]
        state      = key[1]
        hash[created_at.to_date][state] = value
      }

      [{recent_build_history: hash}]
    end

    def streak
      result = @query.streak(@repo)

      start_of_streak = DateTime::Infinity.new
      build_count = 0

      result.each do |builds|
        start_of_streak = builds.created_at if builds.created_at < start_of_streak
        build_count = builds.count.to_i if builds.event_type == "push"
      end

      day_count = (build_count > 0) ? ((Time.now - start_of_streak)/(60*60*24)).floor : 0

      [{streak: {days: day_count, builds: build_count}}]
    end

    private

    # for branches: to avoid division by zero
    def insert_guarded(data, passed, all, branch)
      data[branch] = passed[branch].to_f / all[branch].to_f unless all[branch].to_f == 0
    end

  end
end
