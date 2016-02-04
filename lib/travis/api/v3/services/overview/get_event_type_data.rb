module Travis::API::V3
  class Services::Overview::GetEventTypeData < Service

    def run!
      repo = find(:repository)

      data = {
        'push' => {
          'passed' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => 'push').count,
          'errored' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'errored', :event_type => 'push').count,
          'failed' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'failed', :event_type => 'push').count
        },
        'pull_request' => {
          'passed' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => 'pull_request').count,
          'errored' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'errored', :event_type => 'pull_request').count,
          'failed' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'failed', :event_type => 'pull_request').count
        }
      }

      cron_data = {
        'cron' => {
          'passed' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'passed', :event_type => 'cron').count,
          'errored' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'errored', :event_type => 'cron').count,
          'failed' => Models::Build.where(:repository_id => repo.id, :branch => repo.default_branch_name, :state => 'failed', :event_type => 'cron').count
        }
      }

      data.merge! cron_data unless (cron_data['cron'].all? {|key, value| value <= 0})

      return [{event_type_data: data}]
    end
  end
end
