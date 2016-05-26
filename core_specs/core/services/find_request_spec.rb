require 'spec_helper'

describe Travis::Services::FindRequest do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:request)  { Factory(:request, :repository => repo) }
  let(:params)  { { :id => request.id } }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds a request by the given id' do
      service.run.should == request
    end

    it 'does not raise if the request could not be found' do
      @params = { :id => request.id + 1 }
      lambda { service.run }.should_not raise_error
    end
  end

  describe 'updated_at' do
    it 'returns request\'s updated_at attribute' do
      service.updated_at.to_s.should == request.updated_at.to_s
    end
  end
end
