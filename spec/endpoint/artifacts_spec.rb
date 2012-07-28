require 'spec_helper'

describe Travis::Api::App::Endpoint::Artifacts do
  let(:artifact) { Factory(:log) }
  let(:id) { artifact.id }

  describe 'GET /artifacts/:id' do
    it 'loads the artifact' do
      get("/artifacts/#{id}").should be_ok
    end
  end
end
