require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe 'format_duration' do
    it 'returns nicely formated time' do
      expect(helper.format_duration(0)).to eq('0 sec')
      expect(helper.format_duration(30)).to eq('30 sec')
      expect(helper.format_duration(60)).to eq('1 min 00 sec')
      expect(helper.format_duration(3600)).to eq('1 hrs 00 min 00 sec')
      expect(helper.format_duration(4865)).to eq('1 hrs 21 min 05 sec')
    end
  end

  describe 'format_short_duration' do
    it 'returns short version of nicely formated time' do
      expect(helper.format_short_duration(0)).to eq('0s')
      expect(helper.format_short_duration(30)).to eq('30s')
      expect(helper.format_short_duration(60)).to eq('1m 00s')
      expect(helper.format_short_duration(3600)).to eq('1h 00m 00s')
      expect(helper.format_short_duration(4865)).to eq('1h 21m 05s')
    end
  end
end
