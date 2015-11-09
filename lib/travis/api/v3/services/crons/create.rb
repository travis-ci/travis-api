module Travis::API::V3
  class Services::Crons::Create < Service
    result_type :cron

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      access_control.permissions(repository).create_cron!

      Models::Cron.create(repository: repository)
      end

  end
end
