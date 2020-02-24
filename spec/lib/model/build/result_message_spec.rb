describe Build::ResultMessage do
  def message(data)
    described_class.new(data)
  end

  describe "short" do
    it 'returns :pending if the build is pending' do
      data = { state: :created, previous_state: nil }
      expect(message(data).short).to eq('Pending')
    end

    it 'returns :passed if the build has passed for the first time' do
      data = { state: :passed, previous_state: nil }
      expect(message(data).short).to eq('Passed')
    end

    it 'returns :failed if the build has failed for the first time' do
      data = { state: :failed, previous_state: nil }
      expect(message(data).short).to eq('Failed')
    end

    it 'returns :passed if the build has passed again' do
      data = { state: :passed, previous_state: :passed }
      expect(message(data).short).to eq('Passed')
    end

    it 'returns :broken if the build was broken' do
      data = { state: :failed, previous_state: :passed }
      expect(message(data).short).to eq('Broken')
    end

    it 'returns :fixed if the build was fixed' do
      data = { state: :passed, previous_state: :failed }
      expect(message(data).short).to eq('Fixed')
    end

    it 'returns :failing if the build has failed again' do
      data = { state: :failed, previous_state: :failed }
      expect(message(data).short).to eq('Still Failing')
    end

    it 'returns :errored if the build has errored' do
      data = { state: :errored, previous_state: :failed }
      expect(message(data).short).to eq('Errored')
    end

    it 'returns :canceled if the build has canceled' do
      data = { state: :canceled, previous_state: :failed }
      expect(message(data).short).to eq('Canceled')
    end
  end

  describe "full" do
    it 'returns :pending if the build is pending' do
      data = { state: :created, previous_state: nil }
      expect(message(data).full).to eq('The build is pending.')
    end

    it 'returns :passed if the build has passed for the first time' do
      data = { state: :passed, previous_state: nil }
      expect(message(data).full).to eq('The build passed.')
    end

    it 'returns :failed if the build has failed for the first time' do
      data = { state: :failed, previous_state: nil }
      expect(message(data).full).to eq('The build failed.')
    end

    it 'returns :passed if the build has passed again' do
      data = { state: :passed, previous_state: :passed }
      expect(message(data).full).to eq('The build passed.')
    end

    it 'returns :broken if the build was broken' do
      data = { state: :failed, previous_state: :passed }
      expect(message(data).full).to eq('The build was broken.')
    end

    it 'returns :fixed if the build was fixed' do
      data = { state: :passed, previous_state: :failed }
      expect(message(data).full).to eq('The build was fixed.')
    end

    it 'returns :failing if the build has failed again' do
      data = { state: :failed, previous_state: :failed }
      expect(message(data).full).to eq('The build is still failing.')
    end

    it 'returns :errored if the build has errored' do
      data = { state: :errored, previous_state: :failed }
      expect(message(data).full).to eq('The build has errored.')
    end

    it 'returns :canceled if the build has canceled' do
      data = { state: :canceled, previous_state: :failed }
      expect(message(data).full).to eq('The build was canceled.')
    end
  end

  describe "email" do
    it 'returns :pending if the build is pending' do
      data = { state: :created, previous_state: nil, number: 2 }
      expect(message(data).email).to eq('Build #2 is pending.')
    end

    it 'returns :passed if the build has passed for the first time' do
      data = { state: :passed, previous_state: nil, number: 2 }
      expect(message(data).email).to eq('Build #2 passed.')
    end

    it 'returns :failed if the build has failed for the first time' do
      data = { state: :failed, previous_state: nil, number: 2 }
      expect(message(data).email).to eq('Build #2 failed.')
    end

    it 'returns :passed if the build has passed again' do
      data = { state: :passed, previous_state: :passed, number: 2 }
      expect(message(data).email).to eq('Build #2 passed.')
    end

    it 'returns :broken if the build was broken' do
      data = { state: :failed, previous_state: :passed, number: 2 }
      expect(message(data).email).to eq('Build #2 was broken.')
    end

    it 'returns :fixed if the build was fixed' do
      data = { state: :passed, previous_state: :failed, number: 2 }
      expect(message(data).email).to eq('Build #2 was fixed.')
    end

    it 'returns :failing if the build has failed again' do
      data = { state: :failed, previous_state: :failed, number: 2 }
      expect(message(data).email).to eq('Build #2 is still failing.')
    end

    it 'returns :errored if the build has errored' do
      data = { state: :errored, previous_state: :failed, number: 2 }
      expect(message(data).email).to eq('Build #2 has errored.')
    end

    it 'returns :canceled if the build has canceled' do
      data = { state: :canceled, previous_state: :failed, number: 2 }
      expect(message(data).email).to eq('Build #2 was canceled.')
    end
  end
end
