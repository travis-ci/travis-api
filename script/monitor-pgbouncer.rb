require 'pg'
require 'librato/metrics'

url = ENV['PGBOUNCER_URL'] || 'postgres://pgbouncer:pgbouncer@127.0.0.1:6000/pgbouncer'
interval = ENV['PGBOUNCER_MONITOR_INTERVAL']&.to_i || 10
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
