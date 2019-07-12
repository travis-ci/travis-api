require 'rails_helper'

RSpec.describe Services::Repository::Crons do
  let!(:repo)          { create(:repository) }
  let!(:crons_service) { Services::Repository::Crons.new(repo) }

  fake_crons = "{\"crons\":[{\"branch\":\"master\"}, {\"branch\":\"latest\"}]}"
  fake_crons_after = [{"branch" => "master"}, {"branch" => "latest"}]

  describe '#call' do
    it 'calls travis api /crons endpoint and returns array of available crons' do
      WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repo.slug}/crons").
          to_return(status: 200, body: fake_crons)
      expect(crons_service.call).to eq(fake_crons_after)
    end
  end

  describe '#extract_body' do
    it 'returns body for object with proper body' do
      expect(crons_service.send(:extract_body, OpenStruct.new({ body: '{"crons":[{}, {}]}' }))).to eq([{}, {}])
    end

    it 'returns [] for object with unparsable body' do
      expect(crons_service.send(:extract_body, OpenStruct.new({ body: 'Not a json' }))).to eq([])
    end
  end
end
