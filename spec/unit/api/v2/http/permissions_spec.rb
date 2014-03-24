require 'spec_helper'

describe Travis::Api::V2::Http::Permissions do
  include Travis::Testing::Stubs

  let(:permissions) do
    [
      stub(:repository_id => 1, :admin? => true, :pull? => false, :push? => false),
      stub(:repository_id => 2, :admin? => false, :pull? => true, :push? => false),
      stub(:repository_id => 3, :admin? => false, :pull? => false, :push? => true)
    ]
  end

  let(:data) { Travis::Api::V2::Http::Permissions.new(permissions).data }

  it 'permissions' do
    data['permissions'].should == [1, 2, 3]
  end

  it 'finds admin perms' do
    data['admin'].should == [1]
  end

  it 'finds pull perms' do
    data['pull'].should == [2]
  end

  it 'finds push perms' do
    data['push'].should == [3]
  end
end

