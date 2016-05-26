require 'spec_helper'

describe Travis::Services::FindHooks do
  include Support::ActiveRecord

  let(:user)    { User.first || Factory(:user) }
  let(:repo)    { Factory(:repository) }
  let(:push_repo) { Factory(:repository, name: 'push-repo') }
  let(:service) { described_class.new(user, params) }

  before :each do
    user.permissions.create!(:repository => repo, :admin => true)
    user.permissions.create!(:repository => push_repo, :push => true)
  end

  attr_reader :params

  it 'finds repositories where the current user has access with :all option' do
    @params = { all: true }
    hooks = service.run
    hooks.should include(repo)
    hooks.should include(push_repo)
    hooks.should have(2).items

    # hooks should include admin information
    hooks.sort_by(&:id).map(&:admin?).should == [true, false]
  end

  it 'finds repositories where the current user has admin access' do
    @params = {}
    service.run.should include(repo)
  end

  it 'does not find repositories where the current user does not have admin access' do
    @params = {}
    user.permissions.delete_all
    service.run.should_not include(repo)
  end

  it 'finds repositories by a given owner_name where the current user has admin access' do
    @params = { :owner_name => repo.owner_name }
    service.run.should include(repo)
  end

  it 'does not find repositories by a given owner_name where the current user does not have admin access' do
    @params = { :owner_name => 'rails' }
    service.run.should_not include(repo)
  end
end
