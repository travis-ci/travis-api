require 'spec_helper'

describe Travis::Api::App::Endpoint::Repos do
  before do
    described_class.get('/spec/match/:id')   { "id"   }
    described_class.get('/spec/match/:name') { "name" }
  end

  it 'matches id with digits' do
    get('/repos/spec/match/123').body.should be == "id"
  end

  it 'does not match id with non-digits' do
    get('/repos/spec/match/f123').body.should be == "name"
  end
end
