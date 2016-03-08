module Travis::API::V3
  class Services::Overview::Branches < Service

    def run!
      result = query.branches(find(:repository))

      # output is ordered by branch name
      result.sort! { |a,b| a.branch <=> b.branch }

      passed = Hash.new(0)
      all    = Hash.new(0)

      for builds in result
        if builds.state == "passed"
          passed[builds.branch_name] += builds.count.to_i
        end
        all[builds.branch_name] += builds.count.to_i
      end

      data = {}

      # list default branch first
      default_branch = find(:repository).default_branch.name
      insertGuarded(data, passed, all, default_branch)
      passed.delete(default_branch)
      all.delete(default_branch)

      # after default branch all the other branches (in alphabetical order)
      all.each do |branch, sum|
        insertGuarded(data, passed, all, branch)
      end

      [{branches: data}]
    end

    private

    # to avoid division by zero
    def insertGuarded(data, passed, all, branch)
      data[branch] = passed[branch].to_f / all[branch].to_f unless all[branch].to_f == 0
    end
  end
end
