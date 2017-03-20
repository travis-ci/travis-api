# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'logger'
require 'yaml'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

desc 'Write config file to config/travis.yml'
task 'config', [:env, :pro] do |_t, args|
  logger.debug "args=#{args}"

  pro = args[:pro].to_s
  env = args[:env].to_s

  case pro
  when 'pro'
    kc  = '../travis-pro-keychain'
    arg = '--pro '
  when ''
    kc  = '../travis-keychain'
    arg = ''
  else
    fail "unknown args #{args}"
  end

  heroku_app_name = "travis"

  heroku_app_name << "-pro" if pro == "pro"

  if env == 'staging'
    heroku_app_name << "-staging"
  elsif env == 'production'
    heroku_app_name << "-production"
  else
    fail "unknown args #{args}"
  end

  pwd = Dir.pwd
  Dir.chdir kc
  cmd = "trvs generate-config admin #{env} #{arg}"
  logger.debug "pwd=#{Dir.pwd} cmd=#{cmd}"
  yaml = YAML.load(`#{cmd}`)
  Dir.chdir pwd

  yaml["redis"] = {"url" => "redis://localhost:6379"}
  yaml["disable_otp"] = true

  dev_data = {"development" => yaml}

  config_file = "config/travis.yml"
  logger.info("writing to #{config_file}")
  File.write(config_file, dev_data.to_yaml)

  printf "export GITHUB_LOGIN=\033[31;1mYOUR_OWN_GITHUB_LOGIN\033[0m\n"
  puts "export STAGING_DATABASE_URL=`heroku config:get DATABASE_URL -a #{heroku_app_name}`"
end