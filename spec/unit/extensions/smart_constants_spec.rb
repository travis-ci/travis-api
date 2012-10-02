require 'spec_helper'

describe Travis::Api::App::Extensions::SmartConstants do
  let(:some_app) do
    Sinatra.new { register Travis::Api::App::Extensions::SmartConstants }
  end

  describe :helpers do
    it 'works' do # :)
      some_app.helpers :respond_with
      some_app.ancestors.should include(Travis::Api::App::Helpers::RespondWith)
    end
  end

  describe :register do
    it 'works' do # :)
      some_app.register :subclass_tracker
      some_app.should be_a(Travis::Api::App::Extensions::SubclassTracker)
    end
  end

end
