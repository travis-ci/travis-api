require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'describe' do
    let(:user) { create(:user, name: 'Katrin', login: 'katrina') }
    let(:organization) { create(:organization, name: 'travis', login: 'travis-pro') }
    let(:repository) { create(:repository, owner_name: 'travis') }
    let(:build) { create(:build, repository: repository, number: 123) }
    let(:job) { create(:job, repository: repository, number: 125) }

    it 'returns String to describe a user' do
      expect(helper.describe(user)).to eql 'Katrin (katrina)'
    end

    it 'returns String to describe an organization' do
      expect(helper.describe(organization)).to eql 'travis (travis-pro)'
    end

    it 'returns String to describe a repositories' do
      expect(helper.describe(repository)).to eql 'travis/travis-admin'
    end

    it 'returns String to describe an build' do
      expect(helper.describe(build)).to eql 'travis/travis-admin#123'
    end

    it 'returns String to describe an job' do
      expect(helper.describe(job)).to eql 'travis/travis-admin#125'
    end
  end

  describe 'format_config' do
    it 'prints the string value' do
      expect(helper.format_config('ruby')).to eql 'ruby'
    end

    it 'processes symbols as strings' do
      expect(helper.format_config(:ruby)).to eql 'ruby'
    end

    it 'formats hash values a definition list' do
      expect(helper.format_config({:ruby => 'rails', :over => 9000})).to eql '<dl><dt>ruby:</dt> <dl>rails</dl><dt>over:</dt> <dl>9000</dl></dl>'
    end

    it 'formats array values into a list' do
      expect(helper.format_config([:ruby,'rails',true])).to eql '<ul><li>ruby</li><li>rails</li><li>true</li></ul>'
    end

    it 'prints all other classes as strings' do
      expect(helper.format_config(true)).to eql 'true'
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
