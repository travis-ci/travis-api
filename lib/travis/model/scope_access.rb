module Travis
  module ScopeAccess
    def self.included(base)
      base.class_eval do
        class << self
          def viewable_by(user, repository_id = nil)
            if Travis.config.org?
              self.unscoped
            elsif Travis.config[:public_mode]
              if repository_id
                viewable_in_public_mode_with_repo(user, repository_id)
              else
                viewable_in_public_mode(user)
              end
            else
              if repository_id
                viewable_in_private_mode_with_repo(user, repository_id)
              else
                viewable_in_private_mode(user)
              end
            end
          end

          def viewable_in_public_mode(user)
            if self == ::Repository
              user.nil? ?
                where('repositories.private <> ?', true) :
                where('repositories.private <> ? OR repositories.id IN (?)', true, user.repository_ids)
            elsif self == ::Request
              user.nil? ?
                where('requests.private <> ?', true) :
                where('requests.private <> ? OR requests.repository_id IN (?)', true, user.repository_ids)
            elsif self == ::Build
              user.nil? ?
                where('builds.private <> ?', true) :
                where('builds.private <> ? OR builds.repository_id IN (?)', true, user.repository_ids)
            elsif self == ::BuildBackup
              user.nil? ? where('1=0') : where('build_backups.repository_id IN (?)', user.repository_ids)
            elsif self == ::Job
              user.nil? ?
                where('jobs.private <> ?', true) :
                where('jobs.private <> ? OR jobs.repository_id IN (?)', true, user.repository_ids)
            else
              user.nil? ?
                joins(:repository).where("repositories.private <> ?", true, user.repository_ids) :
                joins(:repository).where("repositories.private <> ? OR #{table_name}.repository_id IN (?)", true, user.repository_ids)
            end
          end

          def viewable_in_public_mode_with_repo(user, repository_id)
            return viewable_in_public_mode(user) unless user

            if self == ::Repository
              return user.repository_ids.include?(repository_id) ?
                where('true') :
                where('repositories.private <> ?', true)
            elsif self == ::Request
              return user.repository_ids.include?(repository_id) ?
                where('true') :
                where('requests.private <> ?', true)
            elsif self == ::Build
              return user.repository_ids.include?(repository_id) ?
                where('true') :
                where('builds.private <> ?', true)
            elsif self == ::BuildBackup
              user.repository_ids.include?(repository_id) ? where('true') : where('false')
            elsif self == ::Job
              return user.repository_ids.include?(repository_id) ?
                where('true') :
                where('jobs.private <> ?', true)
            else
              return user.repository_ids.include?(repository_id) ?
                joins(:repository).where('true') :
                joins(:repository).where("#{table_name}.private <> ?", true)
            end
          end

          def viewable_in_private_mode(user)
            if user.nil?
              where('false')
            elsif self == ::Repository
              where('repositories.id IN (?)', user.repository_ids)
            elsif self == ::Request
              where('requests.repository_id IN (?)', user.repository_ids)
            elsif self == ::Build
              where('builds.repository_id IN (?)', user.repository_ids)
            elsif self == ::BuildBackup
              where('build_backups.repository_id IN (?)', user.repository_ids)
            elsif self == ::Job
              where('jobs.repository_id IN (?)', user.repository_ids)
            else
              where("#{table_name}.repository_id IN (?)", user.repository_ids)
            end
          end

          def viewable_in_private_mode_with_repo(user, repository_id)
            if user.nil?
              where('false')
            elsif self == ::Repository
              user.repository_ids.include?(repository_id) ?
                where('repositories.id = ?', repository_id) :
                where('false')
            elsif self == ::Request
              user.repository_ids.include?(repository_id) ?
                where('requests.repository_id = ?', repository_id) :
                where('false')
            elsif self == ::Build
              user.repository_ids.include?(repository_id) ?
                where('builds.repository_id = ?', repository_id) :
                where('false')
            elsif self == ::Job
              user.repository_ids.include?(repository_id) ?
                where('jobs.repository_id = ?', repository_id) :
                where('false')
            else
              user.repository_ids.include?(repository_id) ?
                where("#{table_name}.repository_id = ?", repository_id) :
                where('false')
            end
          end
        end
      end
    end
  end
end
