module Services
  class Notify
    def initialize(user,string)
      @user = user
      @string = string
    end

    def call
      @string = "#{@user.name} #{@string}" if @user
      @string += '.' if @string =~ /\w\Z/
      unless Rails.env.development?
        Services::Slack.setup
        Service::Slack    << @string
        Travis::DataStores.redis.lpush("admin-v2:logs", "<time>#{Time.now.utc.to_s}</time> #{h(@string)}")
        Travis::DataStores.redis.ltrim("admin-v2:logs", 0, 100)
        puts "=== called slack"
      end
    end

    def h(string)
      Rack::Utils.escape_html(string)
    end
  end
end
