require 'core_ext/hash/deep_symbolize_keys'

describe Build::Config::Matrix do
  it 'can handle nil values in exclude matrix' do
    expect { Build::Config::Matrix.new(matrix: { exclude: [nil] }).expand }.not_to raise_error
  end

  it 'can handle list values in exclude matrix' do
    expect { Build::Config::Matrix.new(matrix: []).expand }.not_to raise_error
  end
end
