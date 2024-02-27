module Travis::API::V3
  class Queries::BuildPermissions < Query
    def find_for_repo(repository)
      Models::Repository.find(repository.id).permissions.joins(:user).includes(:user)
    end

    def find_for_organization(organization)
      Models::Membership.where(organization_id: organization.id).joins(:user).includes(:user)
    end

    def update_for_organization(organization, user_ids, permission)
      Models::Membership.where(organization_id: organization.id, user_id: user_ids).update_all(build_permission: bool(permission))
    end

    def update_for_repo(repository, user_ids, permission)
      roles = ['repository_builds_triggerer', 'repository_builds_restarter']
      user_ids.each do |user_id|
        authorizer = Authorizer::new(user_id)
        if (bool(permission))
          authorizer.patch_repo_roles(repository.id, roles)
        else
          authorizer.delete_repo_roles(repository.id, roles)
        end
      end

      Models::Permission.where(repository_id: repository.id, user_id: user_ids).update_all(build: bool(permission))
    end
  end
end
