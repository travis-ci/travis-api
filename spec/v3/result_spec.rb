require 'spec_helper'

describe Travis::API::V3::Result do
  let(:access_control) { Object.new }
  subject(:result) { described_class.new(access_control, :example, []) }

  example { expect(result.type)           .to be == :example       }
  example { expect(result.resource)       .to be == []             }
  example { expect(result.example)        .to be == []             }
  example { expect(result.access_control) .to be == access_control }
end
