require 'rails_helper'

RSpec.describe Services::Repository::Crons do
  let!(:repo)          { create(:repository) }
  let!(:crons_service) { Services::Repository::Crons.new(repo) }

  fake_crons = [{'branch' => 'master'}, {'branch' => 'latest'}]

  describe '#call' do
    it 'calls travis api /crons endpoint and returns array of available crons' do
      WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repo.slug}/crons").
          to_return(status: 200, body: fake_crons)
      expect(crons_service.call).to eq(fake_crons)
    end
  end

  describe '#extract_body' do
    it 'returns body for object with response lower than 303' do
      expect(crons_service.send(:extract_body, OpenStruct.new({ body: 'present', status: 200 }))).to eq('present')
    end

    it 'returns [] for object with response greater than 303' do
      expect(crons_service.send(:extract_body, OpenStruct.new({ body: 'present', status: 404 }))).to eq([])
    end
  end
end
