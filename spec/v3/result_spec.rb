require 'spec_helper'

describe Travis::API::V3::Result do
  subject(:result) { described_class.new(:example) }

  example { expect(result.type)     .to be == :example  }
  example { expect(result.resource) .to be == []        }
  example { expect(result.example)  .to be == []        }

  example do
    result << 42
    expect(result.example).to include(42)
  end
end
