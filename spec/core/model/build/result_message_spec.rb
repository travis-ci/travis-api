require 'spec_helper'

describe Build::ResultMessage do
  def message(data)
    described_class.new(data)
  end

  describe :short do
    it 'returns :pending if the build is pending' do
      data = { state: :created, previous_state: nil }
      message(data).short.should == 'Pending'
    end

    it 'returns :passed if the build has passed for the first time' do
      data = { state: :passed, previous_state: nil }
      message(data).short.should == 'Passed'
    end

    it 'returns :failed if the build has failed for the first time' do
      data = { state: :failed, previous_state: nil }
      message(data).short.should == 'Failed'
    end

    it 'returns :passed if the build has passed again' do
      data = { state: :passed, previous_state: :passed }
      message(data).short.should == 'Passed'
    end

    it 'returns :broken if the build was broken' do
      data = { state: :failed, previous_state: :passed }
      message(data).short.should == 'Broken'
    end

    it 'returns :fixed if the build was fixed' do
      data = { state: :passed, previous_state: :failed }
      message(data).short.should == 'Fixed'
    end

    it 'returns :failing if the build has failed again' do
      data = { state: :failed, previous_state: :failed }
      message(data).short.should == 'Still Failing'
    end

    it 'returns :errored if the build has errored' do
      data = { state: :errored, previous_state: :failed }
      message(data).short.should == 'Errored'
    end

    it 'returns :canceled if the build has canceled' do
      data = { state: :canceled, previous_state: :failed }
      message(data).short.should == 'Canceled'
    end
  end

  describe :full do
    it 'returns :pending if the build is pending' do
      data = { state: :created, previous_state: nil }
      message(data).full.should == 'The build is pending.'
    end

    it 'returns :passed if the build has passed for the first time' do
      data = { state: :passed, previous_state: nil }
      message(data).full.should == 'The build passed.'
    end

    it 'returns :failed if the build has failed for the first time' do
      data = { state: :failed, previous_state: nil }
      message(data).full.should == 'The build failed.'
    end

    it 'returns :passed if the build has passed again' do
      data = { state: :passed, previous_state: :passed }
      message(data).full.should == 'The build passed.'
    end

    it 'returns :broken if the build was broken' do
      data = { state: :failed, previous_state: :passed }
      message(data).full.should == 'The build was broken.'
    end

    it 'returns :fixed if the build was fixed' do
      data = { state: :passed, previous_state: :failed }
      message(data).full.should == 'The build was fixed.'
    end

    it 'returns :failing if the build has failed again' do
      data = { state: :failed, previous_state: :failed }
      message(data).full.should == 'The build is still failing.'
    end

    it 'returns :errored if the build has errored' do
      data = { state: :errored, previous_state: :failed }
      message(data).full.should == 'The build has errored.'
    end

    it 'returns :canceled if the build has canceled' do
      data = { state: :canceled, previous_state: :failed }
      message(data).full.should == 'The build was canceled.'
    end
  end

  describe :email do
    it 'returns :pending if the build is pending' do
      data = { state: :created, previous_state: nil, number: 2 }
      message(data).email.should == 'Build #2 is pending.'
    end

    it 'returns :passed if the build has passed for the first time' do
      data = { state: :passed, previous_state: nil, number: 2 }
      message(data).email.should == 'Build #2 passed.'
    end

    it 'returns :failed if the build has failed for the first time' do
      data = { state: :failed, previous_state: nil, number: 2 }
      message(data).email.should == 'Build #2 failed.'
    end

    it 'returns :passed if the build has passed again' do
      data = { state: :passed, previous_state: :passed, number: 2 }
      message(data).email.should == 'Build #2 passed.'
    end

    it 'returns :broken if the build was broken' do
      data = { state: :failed, previous_state: :passed, number: 2 }
      message(data).email.should == 'Build #2 was broken.'
    end

    it 'returns :fixed if the build was fixed' do
      data = { state: :passed, previous_state: :failed, number: 2 }
      message(data).email.should == 'Build #2 was fixed.'
    end

    it 'returns :failing if the build has failed again' do
      data = { state: :failed, previous_state: :failed, number: 2 }
      message(data).email.should == 'Build #2 is still failing.'
    end

    it 'returns :errored if the build has errored' do
      data = { state: :errored, previous_state: :failed, number: 2 }
      message(data).email.should == 'Build #2 has errored.'
    end

    it 'returns :canceled if the build has canceled' do
      data = { state: :canceled, previous_state: :failed, number: 2 }
      message(data).email.should == 'Build #2 was canceled.'
    end
  end
end
