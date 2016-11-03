require 'rails_helper'

RSpec.describe Offender, type: :model do
  let!(:user) { create :user}
  let!(:organization) { create :organization }
  let(:redis) { Travis::DataStores.redis }

  before { redis.sadd('abuse:offenders', "#{user.login}")
           redis.sadd('abuse:offenders', "#{organization.login}") }

  describe '.logins' do
    it 'returns an array with offender logins' do
      expect(Offender.logins.length).to eql 2
      expect(Offender.logins).to include 'travisbot'
      expect(Offender.logins).to include 'travis-pro'
    end
  end

  describe '.users' do
    it 'returns an array with users that are marked as offender' do
      expect(Offender.users.length).to eql 1
      expect(Offender.users).to include user
    end
  end

  describe '.organizations' do
    it 'returns an array with organizations that are marked as offender' do
      expect(Offender.organizations.length).to eql 1
      expect(Offender.organizations).to include organization
    end
  end
end
