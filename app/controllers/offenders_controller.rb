class OffendersController < ApplicationController
  def index
    @offending_users = Offender.users
    @offending_organizations = Offender.organizations
  end
end
