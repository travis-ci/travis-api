module Travis::API::V3
  class Services::Overview::Branches < Service

    def run!
      repo = find(:repository)
      branches = repo.branches
      data = {}
      branches.each do |branch|
        passed = Models::Build.where(:repository_id => repo.id, :branch => branch.name, :event_type => ['push', 'cron'], :state => 'passed').where("created_at > ?", Date.today - 30).count
        all    = Models::Build.where(:repository_id => repo.id, :branch => branch.name, :event_type => ['push', 'cron']).where("created_at > ?", Date.today - 30).count
        if all > 0
          data[branch.name] = passed.to_f / all
        end
      end

      [{branches: data}]
    end
  end
end
