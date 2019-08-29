# TODO Rename github_id to vcs_id after migration
module User::Renaming
  def nullify_logins(vcs_id, login)
    users = User.where(["github_id <> ? AND login = ?", vcs_id, login])
    if users.exists?
      Travis.logger.info("About to nullify login (#{login}) for users: #{users.map(&:id).join(', ')}")
      users.update_all(login: nil)
    end

    organizations = Organization.where(["login = ?", login])
    if organizations.exists?
      Travis.logger.info("About to nullify login (#{login}) for organizations: #{organizations.map(&:id).join(', ')}")
      organizations.update_all(login: nil)
    end
  end

  def rename_repos_owner(old_login, new_login)
    return if old_login == new_login
    Repository.where(owner_name: old_login).
               update_all(owner_name: new_login)
  end
end
