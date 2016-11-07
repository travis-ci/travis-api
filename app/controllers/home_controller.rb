class HomeController < ApplicationController
  def home
  end

  def logout
    reset_session
  end

  def not_found
  end
end
