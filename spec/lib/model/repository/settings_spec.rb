# encoding: utf-8
describe Repository::Settings do
  describe 'env_vars' do
    it 'can be filtered to get only public vars' do
      settings = Repository::Settings.load(env_vars: [
        { name: 'PUBLIC_VAR', value: 'public var', public: true },
        { name: 'SECRET_VAR', value: 'secret var', public: false }
      ])
      expect(settings.env_vars.public.length).to eq(1)
      expect(settings.env_vars.public.first.name).to eq('PUBLIC_VAR')
    end
  end

  describe '#maximum_number_of_builds' do
    it 'defaults to 0' do
      settings = Repository::Settings.new(maximum_number_of_builds: nil)
      expect(settings.maximum_number_of_builds).to eq(0)
    end
  end

  describe '#restricts_number_of_builds?' do
    it 'returns true if number of builds is restricted' do
      settings = Repository::Settings.new(maximum_number_of_builds: 2)
      expect(settings.restricts_number_of_builds?).to be true
    end

    it 'returns false if builds are not restricted' do
      settings = Repository::Settings.new(maximum_number_of_builds: 0)
      expect(settings.restricts_number_of_builds?).to be false
    end
  end

  it 'validates maximum_number_of_builds' do
    settings = Repository::Settings.new
    settings.maximum_number_of_builds = nil
    expect(settings).to be_valid

    settings.maximum_number_of_builds = 'foo'
    expect(settings).not_to be_valid
    expect(settings.errors.details[:maximum_number_of_builds].map{|k| k[:error]}).to eq([:not_a_number])

    settings.maximum_number_of_builds = 0
    expect(settings).to be_valid
  end

  describe '#api_builds_rate_limit' do
    it 'saves new api_builds_rate_limit if rate is under 200' do
      settings = Repository::Settings.new(api_builds_rate_limit: 2)
      expect(settings).to be_valid
    end

    it 'does not save new api_builds_rate_limit if rate is over 200' do
      settings = Repository::Settings.new(api_builds_rate_limit: 201)
      expect(settings).not_to be_valid
    end

    it 'returns nil if no api_builds_rate_limit is set on settings' do
      settings = Repository::Settings.new()
      expect(settings.api_builds_rate_limit).to eq(nil)
    end
  end

  describe 'timeouts' do
    MAX = {
      off: { hard_limit: 180, log_silence: 60 },
      on:  { hard_limit: 180, log_silence: 60 }
    }

    [:hard_limit, :log_silence].each do |type|
      describe type do
        def settings(type, value)
          Repository::Settings.load({ :"timeout_#{type}" => value }, repository_id: 1)
        end

        it 'defaults to nil' do
          expect(settings(type, nil).send(:"timeout_#{type}")).to be_nil
        end

        it "is valid if #{type} is nil" do
          expect(settings(type, nil)).to be_valid
        end

        it 'returns nil if set to 0' do
          expect(settings(type, 0).send(:"timeout_#{type}")).to be_nil
        end

        it "is valid if #{type} is set to 0" do
          expect(settings(type, 0)).to be_valid
        end

        [:off, :on].each do |status|
          describe "with :custom_timeouts feature flag turned #{status}" do
            max = MAX[status][type]

            before :each do
              allow(Travis::Features).to receive(:repository_active?).with(:custom_timeouts, 1).and_return true if status == :on
            end

            describe 'is valid' do
              it "if #{type} is nil" do
                expect(settings(type, nil)).to be_valid
              end

              it "if #{type} is > 0" do
                expect(settings(type, 1)).to be_valid
              end

              it "if #{type} is < #{max}" do
                expect(settings(type, max - 1)).to be_valid
              end

              it "if #{type} equals #{max}" do
                expect(settings(type, max)).to be_valid
              end
            end

            describe 'is invalid' do
              it "if #{type} is < 0" do
                expect(settings(type, -1)).not_to be_valid
              end

              it "if #{type} is > #{max}" do
                expect(settings(type, max + 1)).not_to be_valid
              end
            end

            it 'adds an error message if invalid' do
              model = settings(type, - 1)
              model.valid?
              expect(model.errors[:"timeout_#{type}"]).to eq(["Invalid #{type} timeout value (allowed: 0 - #{max})"])
            end
          end
        end
      end
    end
  end
end
