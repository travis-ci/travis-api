describe Travis::Api::App::Extensions::SmartConstants do
  let(:some_app) do
    Sinatra.new { register Travis::Api::App::Extensions::SmartConstants }
  end

  describe :helpers do
    it 'works' do # :)
      some_app.helpers :respond_with
      expect(some_app.ancestors).to include(Travis::Api::App::Helpers::RespondWith)
    end
  end

  describe :register do
    it 'works' do # :)
      some_app.register :subclass_tracker
      expect(some_app).to be_a(Travis::Api::App::Extensions::SubclassTracker)
    end
  end

end
