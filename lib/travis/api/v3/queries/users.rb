module Travis::API::V3
  class Queries::Users < Query
    params :user_ids, :vcs_ids, :vcs_type

    def suspend(value)
      if params['vcs_type']
       raise WrongParams, 'missing user ids'.freeze unless params['vcs_ids']&.size > 0

      ids = Models::User.where("vcs_type = ? and vcs_id in (?)", vcs_type, params['vcs_ids']).all.map(&:id)
     else
       raise WrongParams, 'missing user ids'.freeze unless params['user_ids']&.size > 0

      ids = params['user_ids']
     end
      Models::User.where('id in (?)' , ids).update!(suspended: value, suspended_at: value ? Time.now.utc : nil)
      skipped =  unknown_ids(ids)
      Models::BulkChangeResult.new(
        changed: ids - skipped,
        skipped: skipped
      )
    end

    def unknown_ids(ids)
      @_unknown_ids ||= ids - User.where('id in (?)', ids).all.map(&:id)
    end

    private

    def vcs_type
      @_vcs_type ||=
        params['vcs_type'] ?
          (
            params['vcs_type'].end_with?('User') ?
              params['vcs_type'] :
              "#{params['vcs_type'].capitalize}User"
          )
        : 'GithubUser'
    end
  end
end
