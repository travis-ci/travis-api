describe Travis::API::V3::Models::ScannerCollection do
  let(:collection) { [ { id: 1, name: 'test1' }, { id: 2, name: 'test2' }, { id: 3, name: 'test3' } ] }
  subject { Travis::API::V3::Models::ScannerCollection.new(collection, collection.count) }

  describe "#count" do
    it 'returns total_count' do
      expect(subject.count).to eq(collection.count)
    end
  end

  describe "#limit" do
    it 'returns self' do
      expect(subject.limit).to eq(subject)
    end
  end

  describe "#offset" do
    it 'returns self' do
      expect(subject.offset).to eq(subject)
    end
  end

  describe "#map" do
    it 'returns map on collection' do
      expect(subject.map { |e| e[:id] }).to eq([1, 2, 3])
    end
  end

  describe "#to_sql" do
    before { Timecop.freeze(Time.now.utc) }

    it 'returns placeholder string' do
      expect(subject.to_sql).to eq("scanner_query:#{Time.now.to_i}")
    end
  end
end
