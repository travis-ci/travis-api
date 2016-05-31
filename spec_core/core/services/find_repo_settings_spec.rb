require 'spec_helper'

describe Travis::Services::FindRepoSettings do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository) }
  let(:params)  { { id: repo.id } }
  let(:user)    { Factory(:user) }
  let(:service) { described_class.new(user, params) }

  before do
    repo.settings.merge('build_pushes' => false)
    repo.settings.save
    repo.save
  end

  describe 'authorized?' do
    let(:service) { described_class.new(nil, params) }

    it 'should be unauthorized with current_user' do
      service.should_not be_authorized
    end
  end

  describe 'run' do
    it 'should return nil without a repo' do
      repo.destroy
      service.run.should be_nil
    end

    it 'should return repo settings' do
      user.permissions.create(repository_id: repo.id, push: true)
      service.run.to_hash.should == repo.settings.to_hash
    end

    it 'should not be able to get settings if user does not have push permission' do
      user.permissions.create(repository_id: repo.id, push: false)

      service.run.should be_nil
    end
  end
end

