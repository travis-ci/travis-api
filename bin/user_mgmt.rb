$LOAD_PATH << File.expand_path('../../lib', __FILE__)
$stdout.sync = true

require 'bundler/setup'

require 'active_record'
require "stringio"
require 'travis/config'
require 'marginalia'

# Temp redirect of output
def silence(&block)
  previous_stdout, $stdout = $stdout, StringIO.new
  previous_stderr, $stderr = $stderr, StringIO.new
  block.call
ensure
  $stdout = previous_stdout
  $stderr = previous_stderr
end

Marginalia.set('app', 'api')
Marginalia.set('script', 'user_mgmt')
Marginalia.set('dyno', ENV['DYNO'])

# Setup model
ActiveRecord::Base.establish_connection(Travis::Config.load.database.to_h)
class User < ActiveRecord::Base
  default_scope        { where('login IS NOT NULL') }
  scope :active,    -> { where('github_oauth_token IS NOT NULL AND suspended = false') }
  scope :inactive,  -> { where('github_oauth_token IS NULL AND suspended = false') }
  scope :suspended, -> { where(suspended: true) }
  scope :alpha,     -> { order(login: :asc) }

  def enterprise_status
    case
    when suspended
      "Suspended #{suspended_at.strftime('%F')}"
    when !github_oauth_token
      'Inactive'
    else
      'Active'
    end
  end
end

# Triggers autoloading of pg gem, which has deprecation warnings at v0.21.0
silence { User.connection }
