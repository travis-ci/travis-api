require 'spec_helper'

describe Travis::Api::App::Endpoint::Builds do
  include Travis::Testing::Stubs

  it 'works with default options' do
    get('/repos.json', {}).should be_ok
  end

  context '/repos.json is requested' do
    before :each do
      @plain_response_body = get('/repos.json').body
    end

    context 'when `pretty=true` is given' do
      it 'prints pretty formatted data' do
        response = get('/repos.json?pretty=true')
        response.should be_ok
        response.body.should_not eq(@plain_response_body)
        response.body.should match(/\n/)
      end
    end

    context 'when `pretty=1` is given' do
      it 'prints pretty formatted data' do
        response = get('/repos.json?pretty=1')
        response.should be_ok
        response.body.should_not eq(@plain_response_body)
        response.body.should match(/\n/)
      end
    end

    context 'when `pretty=bogus` is given' do
      it 'prints plain-formatted data' do
        response = get('/repos.json?pretty=bogus')
        response.should be_ok
        response.body.should eq(@plain_response_body)
      end
    end
  end
  
end
