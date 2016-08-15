class AdminsController < ApplicationController
  def index
    @admins = Admin.users
  end
end
