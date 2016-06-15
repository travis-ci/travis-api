require 'spec_helper'

describe Travis::Services::FindRepoKey do
  include Support::ActiveRecord

  let!(:repo)   { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds a key by the given repository id' do
      @params = { :id => repo.id }
      service.run.should == repo.key
    end

    it 'finds a key by the given owner_name and name' do
      @params = { :owner_name => repo.owner_name, :name => repo.name }
      service.run.should == repo.key
    end
  end

  describe 'updated_at' do
    it 'returns key\'s updated_at attribute' do
      @params = { :id => repo.id }
      service.updated_at.to_s.should == repo.key.updated_at.to_s
    end
  end
end
