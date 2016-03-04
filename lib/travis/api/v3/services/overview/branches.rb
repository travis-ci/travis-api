module Travis::API::V3
  class Services::Overview::Branches < Service

    def run!
      result = query.branches(find(:repository))

      passed = Hash.new(0)
      all    = Hash.new(0)

      for builds in result
        if builds.state == "passed"
          passed[builds.branch_name] += builds.count.to_i
        end
        all[builds.branch_name] += builds.count.to_i
      end

      data = {}
      all.each do |branch, all|
        data[branch] = passed[branch].to_f / all
      end

      [{branches: data}]
    end
  end
end
