#!/bin/env ruby

require 'csv'
require 'erb'

versions = %w(v2.1 v2 v1)
modes = %w(private public)
visibilities = %w(private public)
contexts = {
  with_permission: 'auth/perm',
  without_permission: 'auth/no perm',
  unauthenticated: 'unauth'
}

csv   = File.read(File.expand_path('../auth.csv', __FILE__))
@data = CSV.parse(csv, headers: true).map(&:to_h)
paths = @data.map { |row| [row['resource'], row['path']] }.uniq.sort
paths = paths.reject { |resource, _| resource == 'switch' }

def status(path, version, mode, visibility, context)
  row = @data.detect do |row|
    row['path']    == path &&
    row['version'] == version &&
    row['mode']    == mode &&
    row['repo']    == visibility &&
    row['context'] == context
  end || @data.detect do |row|
    row['path']    == path &&
    row['version'] == version &&
    row['mode']    == mode &&
    (row['repo'].nil? && visibility.nil?) &&
    row['context'] == context
  end

  if row
    blank = '(empty)' if row['empty'] == 'yes'
    [row['status'], blank].compact.join(' ')
  elsif context == 'with_permission'
    # hrmmmm.
    status(path, version, mode, visibility, 'authenticated') ||
    status(path, version, mode, nil, 'authenticated')
  end
end

erb  = File.read(File.expand_path('../table.erb', __FILE__))
html = ERB.new(erb).result(binding)
puts html
