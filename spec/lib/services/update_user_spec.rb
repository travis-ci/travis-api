describe Travis::Services::UpdateUser do
  include Travis::Testing::Stubs

  let(:service)   { described_class.new(user, params) }

  before :each do
    allow(user).to receive(:update!)
  end

  attr_reader :params

  it 'updates the locale if valid' do
    @params = { :locale => 'en' }
    expect(user).to receive(:update!).with(params)
    service.run
  end

  it 'does not update the locale if invalid' do
    @params = { :locale => 'foo' }
    expect(user).not_to receive(:update!)
    service.run
  end
end
