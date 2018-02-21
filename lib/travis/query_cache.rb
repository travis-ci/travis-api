require 'active_record/query_cache'
require 'active_support/executor'

# This is a replacement for ActiveRecord::QueryCache
# which used to be a middleware but was removed in
# Rails 5.
#
# See https://github.com/rails/rails/issues/26947
#
# Implementation cribbed from
# https://github.com/rails/rails/commit/d3c9d808e3e242155a44fd2a89ef272cfade8fe8#diff-7521c0bb452244663b689e77658e63e3R212
class QueryCache
  def initialize(app)
    @app = app
    @exec = Class.new(ActiveSupport::Executor)
    ActiveRecord::QueryCache.install_executor_hooks(@exec)
  end

  def call(env)
    @exec.wrap { @app.call(env) }
  end
end
