require 'spec_helper'
require 'core_ext/hash/deep_symbolize_keys'

describe Build::Config::Matrix do
  include Support::ActiveRecord

  it 'can handle nil values in exclude matrix' do
    -> { Build::Config::Matrix.new(matrix: { exclude: [nil] }).expand }.should_not raise_error
  end

  it 'can handle list values in exclude matrix' do
    -> { Build::Config::Matrix.new(matrix: []).expand }.should_not raise_error
  end
end
