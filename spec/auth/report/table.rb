#!/bin/env ruby

require 'csv'
require 'erb'

versions = %w(v2.1 v2 v1)
modes = %w(private public)
visibilities = %w(private public)
contexts = {
  with_permission: 'perm',
  without_permission: 'no perm',
  unauthenticated: 'unauth'
}

csv   = File.read(File.expand_path('../auth.csv', __FILE__))
@data = CSV.parse(csv, headers: true).map(&:to_h)
paths = @data.map { |row| row['path'] }.uniq.sort

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
    row['context'] == context
  end

  # if path == '/repos/%{repo.slug}?token=%{user.token}' && mode == 'private' && visibility == 'private' && version == 'v2.1'
  #   p [version, mode, visibility, context]
  #   p row
  # end

  if row
    blank = '(empty)' if row['empty'] == 'yes'
    [row['status'], blank].compact.join(' ')
  elsif context == 'with_permission'
    status(path, version, mode, nil, 'authenticated')
  else
    '-'
  end
end

erb  = File.read(File.expand_path('../table.erb', __FILE__))
html = ERB.new(erb).result(binding)
# puts html
