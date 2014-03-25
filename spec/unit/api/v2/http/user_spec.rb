require 'spec_helper'

describe Travis::Api::V2::Http::User do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { Travis::Api::V2::Http::User.new(user).data }

  it 'user' do
    data['user'].should == {
      'id' => 1,
      'name' => 'Sven Fuchs',
      'login' => 'svenfuchs',
      'email' => 'svenfuchs@artweb-design.de',
      'gravatar_id' => '402602a60e500e85f2f5dc1ff3648ecb',
      'locale' => 'de',
      'is_syncing' => false,
      'synced_at' => json_format_time(Time.now.utc - 1.hour),
      'correct_scopes' => true,
      'created_at' => json_format_time(Time.now.utc - 2.hours),
    }
  end
end

