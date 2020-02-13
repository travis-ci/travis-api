describe Travis::Api::App do
  describe :setup? do
    it 'indicates if #setup has been called' do
      Travis::Api::App.setup
      expect(Travis::Api::App).to be_setup
    end
  end
end
