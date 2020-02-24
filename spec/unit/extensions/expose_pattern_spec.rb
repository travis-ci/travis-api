class Foo < Sinatra::Base
  register Travis::Api::App::Extensions::ExposePattern

  get '/:id' do
    "ok"
  end
end

describe Travis::Api::App::Extensions::ExposePattern do
  before { set_app(Foo) }

  example "it exposes the pattern" do
    expect(get('/foo')).to be_ok
    expect(headers['X-Pattern']).to eq('/:id')
  end

  example "it exposes the app class" do
    expect(get('/foo')).to be_ok
    expect(headers['X-Endpoint']).to eq('Foo')
  end
end
