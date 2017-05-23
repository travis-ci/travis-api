require 'pg'
require 'uri'
require 'librato/metrics'

if ENV['PGBOUNCER_URL']
  url = ENV['PGBOUNCER_URL']
else
  url = 'postgres://pgbouncer@127.0.0.1:6000/pgbouncer'
end

interval = ENV['PGBOUNCER_MONITOR_INTERVAL'] || 10
librato_source = ENV['DYNO']

Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']

conn = PGconn.open(url)

loop do
  res  = conn.exec('SHOW POOLS')
  res.each do |row|
    keys = %w(cl_active cl_waiting sv_active sv_idle sv_used sv_tested sv_login maxwait)

    queue = Librato::Metrics::Queue.new
    keys.each do |k|
      queue.add "pgbouncer.#{row['database']}.#{k}": { source: librato_source, value: row[k] }
    end
    queue.submit
  end

  sleep interval
end
