module Travis::API::V3
  class Services::Crons::Create < Service


    def run!
      #raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      #access_control.permissions(cron).create!

      Models::Cron.create(repository: repository)
      query.find(find(:repository))
      end

  end
end
