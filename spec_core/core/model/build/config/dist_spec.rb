require 'travis/model/build/config/dist'

describe Build::Config::Dist do
  subject { described_class.new(config, options) }
  let(:config) { {} }
  let(:options) { {} }

  it 'sets dist to the default' do
    subject.run[:dist].should eql(described_class::DEFAULT_DIST)
  end

  context 'with :dist' do
    let(:config) { { dist: 'hambone' } }

    it 'is a no-op' do
      subject.run[:dist].should eql('hambone')
    end
  end

  context "with 'dist'" do
    let(:config) { { 'dist' => 'lentil' } }

    it 'is a no-op' do
      subject.run['dist'].should eql('lentil')
    end
  end

  context 'with an override language' do
    let(:config) { { language: language } }
    let(:language) { described_class::DIST_LANGUAGE_MAP.keys.sample }

    it 'sets the override for that language' do
      subject.run[:dist].should eql(
        described_class::DIST_LANGUAGE_MAP[language]
      )
    end
  end

  context 'with an override os' do
    let(:config) { { os: os } }
    let(:os) { described_class::DIST_OS_MAP.keys.sample }

    it 'sets the override for that os' do
      subject.run[:dist].should eql(described_class::DIST_OS_MAP[os])
    end
  end

  context 'with an override language and os' do
    let(:config) { { language: language, os: os } }
    let(:language) { described_class::DIST_LANGUAGE_MAP.keys.sample }
    let(:os) { described_class::DIST_OS_MAP.keys.sample }

    it 'sets the override for that language' do
      subject.run[:dist].should eql(
        described_class::DIST_LANGUAGE_MAP[language]
      )
    end
  end

  context 'with multi_os option and override language set' do
    let(:config) { { language: language } }
    let(:options) { { multi_os: true } }
    let(:language) { described_class::DIST_LANGUAGE_MAP.keys.sample }

    it 'sets the override for that language' do
      subject.run[:dist].should eql(
        described_class::DIST_LANGUAGE_MAP[language]
      )
    end
  end

  context 'with multi_os option and non-override language set' do
    let(:config) { { language: 'goober' } }
    let(:options) { { multi_os: true } }
    let(:language) { described_class::DIST_LANGUAGE_MAP.keys.sample }

    it 'sets dist to the default' do
      subject.run[:dist].should eql(described_class::DEFAULT_DIST)
    end
  end

  context 'without multi_os and os array with override first entry' do
    let(:config) { { os: %w(osx linux) } }
    let(:options) { { multi_os: false } }

    it 'sets the override for that os' do
      subject.run[:dist].should eql(described_class::DIST_OS_MAP['osx'])
    end
  end

  context 'without multi_os and os array without override first entry' do
    let(:config) { { os: %w(freebsd osx linux) } }
    let(:options) { { multi_os: false } }

    it 'sets dist to the default' do
      subject.run[:dist].should eql(described_class::DEFAULT_DIST)
    end
  end

  context 'with docker in services' do
    let(:config) { { services: %w(docker) } }

    it 'sets the dist to trusty' do
      subject.run[:dist].should eql('trusty')
    end
  end

  context 'with docker in matrix include services' do
    let(:config) do
      {
        matrix: { include: [{ services: %w(docker postgresql) }] },
        services: %w(postgresql)
      }
    end

    it 'sets the dist to trusty in the include hash' do
      subject.run[:matrix][:include].first[:dist].should eql('trusty')
    end

    it 'sets the dist to the default at the top level' do
      subject.run[:dist].should eql(described_class::DEFAULT_DIST)
    end
  end
end
