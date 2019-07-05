class UnknownController < ApplicationController
  def canonical_route
    redirect_to "/?q=#{params['other']}"
  end
end