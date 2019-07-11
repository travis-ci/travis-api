module PermittedParams
  def permitted_keep_netrc(params)
    params.permit(:keep_netrc).delete_if { |key, val| key == 'keep_netrc' && !val.in?(%w[0 1]) }
  end
end