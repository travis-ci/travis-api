require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe 'format_duration' do
    it 'returns nicely formated time' do
      expect(helper.format_duration(30)).to eq('30 sec')
      expect(helper.format_duration(60)).to eq('1 min')
      expect(helper.format_duration(3600)).to eq('1 hrs')
      expect(helper.format_duration(4865)).to eq('1 hrs 21 min 5 sec')
    end
  end

  describe 'format_short_duration' do
    it 'returns nicely formated time' do
      expect(helper.format_short_duration(30)).to eq('30s')
      expect(helper.format_short_duration(60)).to eq('1m')
      expect(helper.format_short_duration(3600)).to eq('1h')
      expect(helper.format_short_duration(4865)).to eq('1h 21m 5s')
    end
  end

  describe 'describe' do
    let!(:repository) { create(:repository, owner_name: 'travis') }

    it 'returns String to describe a repositories' do
      expect(helper.describe(repository)).to eql 'travis/travis-admin'
    end
  end
end
