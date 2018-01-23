module Travis
  module ScopeAccess
    def self.included(base)
      base.class_eval do
        class << self
          def viewable_by(user)
            if Travis.config.org?
              self
            elsif Travis.config[:public_mode]
              viewable_in_public_mode(user)
            else
              viewable_in_private_mode(user)
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

          def viewable_in_private_mode(user)
            if user.nil?
              where('false')
            elsif self == ::Repository
              where('repositories.id IN (?)', user.repository_ids)
            elsif self == ::Request
              where('requests.repository_id IN (?)', user.repository_ids)
            elsif self == ::Build
              where('builds.repository_id IN (?)', user.repository_ids)
            elsif self == ::Job
              where('jobs.repository_id IN (?)', user.repository_ids)
            else
              where("#{table_name}.repository_id IN (?)", user.repository_ids)
            end
          end
        end
      end
    end
  end
end
