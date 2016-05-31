require 'travis/model/build/config/group'

describe Build::Config::Group do
  subject { described_class.new(config) }
  let(:config) { { dist: 'bork' } }

  it 'sets group to the default' do
    subject.run[:group].should eql(described_class::DEFAULT_GROUP)
  end

  context 'with :group' do
    let(:config) { { group: 'foo' } }

    it 'is a no-op' do
      subject.run[:group].should eql('foo')
    end
  end

  context "with 'group'" do
    let(:config) { { 'group' => 'bar' } }

    it 'is a no-op' do
      subject.run['group'].should eql('bar')
    end
  end
end
