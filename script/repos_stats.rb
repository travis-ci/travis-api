$stdout.sync = true

Repository.where('last_build_finished_at is not null').count(group: :github_language)

rates = Repository.where('last_build_finished_at is not null').count(group: [:last_build_state, :github_language])
groups = rates.group_by { |k, v| k[1] }
stats = groups.map do |lang, values|
  values.inject({ "language" => lang || 'unknown' }) do |result, (state, count)|
    result.merge(state[0] => count)
  end
end

keys = %w(language total passed failed errored cancelled)
puts keys.join(',')

rows = stats.map do |stat|
  values = stat.values
  row = [values.shift]
  row << stat.values[1..-1].inject(&:+)
  keys[1..-1].each { |key| row << (stat[key] || 0) }
  row
end

rows = rows.sort_by { |row| row[1] }.reverse
csv = rows.map { |row| row.join(',') }
puts csv.join("\n")
