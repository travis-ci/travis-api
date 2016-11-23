require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  let!(:user) { create(:user) }
  let!(:organization) { create(:organization) }

  let(:redis) { Travis::DataStores.redis }

  describe 'access_token' do
    it 'generates an access token' do
      expect(helper.access_token(user)).to be_instance_of(Travis::AccessToken)
    end

    it 'sets correct values in redis' do
      access_token = helper.access_token(user).token

      expect(access_token).to eq(redis.get("r:#{user.id}:2"))
      expect(redis.lrange("t:#{access_token}", 0, -1)).to eq(["#{user.id}", '2', 'public', 'private'])
    end
  end

  describe 'check_trial_builds' do
    let(:redis) { Travis::DataStores.redis }
    before { redis.set("trial:#{user.login}", '75') }

    it 'returns formatted trial builds when they exist' do
      expect(helper.check_trial_builds(user)).to eq('75 trial builds')
    end

    it 'returns not in trial when trial does not exist' do
      expect(helper.check_trial_builds(organization)).to eq('not in trial')
    end
  end

  describe 'describe' do
    let(:repository) { create(:repository) }
    let(:build) { create(:build, repository: repository) }
    let(:job) { create(:job, repository: repository, build: build) }
    let(:request) { create(:request) }

    it 'returns String to describe a user' do
      expect(helper.describe(user)).to eql 'Travis (travisbot)'
    end

    it 'returns String to describe an organization' do
      expect(helper.describe(organization)).to eql 'Travis (travis-pro)'
    end

    it 'returns String to describe a repositories' do
      expect(helper.describe(repository)).to eql 'travis-pro/travis-admin'
    end

    it 'returns String to describe an build' do
      expect(helper.describe(build)).to eql 'travis-pro/travis-admin#123'
    end

    it 'returns String to describe an job' do
      expect(helper.describe(job)).to eql 'travis-pro/travis-admin#123.4'
    end

    it 'returns String to describe a request' do
      expect(helper.describe(request)).to eql '#12345'
    end
  end

  describe 'stringify_hash_keys' do
    it 'converts key symbols to key strings' do
      expect(helper.stringify_hash_keys({:a=> "b", :c=> "d"})).to eq({"a"=>"b", "c"=>"d"})
    end

    it 'converts key symbols to key strings when nested in arrays' do
      expect(helper.stringify_hash_keys([{a: :b, c: :d}])).to eq([{"a"=>:b, "c"=>:d}])
    end
  end

  describe 'format_duration' do
    it 'returns nicely formatted time' do
      expect(helper.format_duration(0)).to eq('0 sec')
      expect(helper.format_duration(30)).to eq('30 sec')
      expect(helper.format_duration(60)).to eq('1 min 00 sec')
      expect(helper.format_duration(3600)).to eq('1 hrs 00 min 00 sec')
      expect(helper.format_duration(4865)).to eq('1 hrs 21 min 05 sec')
    end
  end

  describe 'format_file_size' do
    it 'returns formatted file sizes' do
      expect(helper.format_file_size(0)).to eq('0 B')
      expect(helper.format_file_size(123)).to eq('123 B')
      expect(helper.format_file_size(12340)).to eq('12.05 KiB')
      expect(helper.format_file_size(12340000)).to eq('11.77 MiB')
      expect(helper.format_file_size(12340000000)).to eq('11.49 GiB')
      expect(helper.format_file_size(12340000000000)).to eq('11.22 TiB')
      expect(helper.format_file_size(12340000000000000)).to eq('10.96 PiB')
      expect(helper.format_file_size(12340000000000000000)).to eq('10.7 EiB')
      expect(helper.format_file_size(12340000000000000000000)).to eq('10.45 ZiB')
      expect(helper.format_file_size(12340000000000000000000000)).to eq('10.21 YiB')
    end
  end

  describe 'format_short_duration' do
    it 'returns short version of nicely formatted time' do
      expect(helper.format_short_duration(0)).to eq('0s')
      expect(helper.format_short_duration(30)).to eq('30s')
      expect(helper.format_short_duration(60)).to eq('1m 00s')
      expect(helper.format_short_duration(3600)).to eq('1h 00m 00s')
      expect(helper.format_short_duration(4865)).to eq('1h 21m 05s')
    end
  end
end
