module Travis::API::V3
  class Services::Cron::Delete < Service
    def run!
      cron = check_login_and_find
      return repo_migrated if migrated?(cron.branch.repository)

      access_control.permissions(cron).delete!
      cron.destroy
      no_content
    end
  end
end
