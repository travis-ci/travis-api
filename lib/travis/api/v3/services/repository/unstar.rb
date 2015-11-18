module Travis::API::V3
  class Services::Repository::Unstar < Service
    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      Models::StarredRepository.where(repository_id: repository.id, user_id: access_control.user.id).delete

      # repository #TODO what do we want to return???
    end

    # def check_access(repository)
    #   access_control.permissions(repository).unstar!
    # end
  end
end
