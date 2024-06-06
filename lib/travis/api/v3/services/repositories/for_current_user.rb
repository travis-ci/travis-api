module Travis::API::V3
  class Services::Repositories::ForCurrentUser < Service
    params :active, :private, :starred, :name_filter, :slug_filter,
      :managed_by_installation, :active_on_org, prefix: :repository
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      t1 = Time.now
      q = query.for_member(access_control.user)
      t2 = Time.now
      res = result q
      puts "query: #{(t2-t1).in_milliseconds}\nresult query: #{(Time.now - t2).in_milliseconds}"
      res
    end
  end
end
