module OrganizationHelper
  def vcs_organization_profile_url(organization)
    Travis::Providers.get(organization.vcs_type).new(organization).profile_link
  end

  def manage_repo_link_url(organization)
    Travis::Providers.get(organization.vcs_type).new(organization).manage_repo_link
  end
end
