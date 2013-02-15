require 'spec_helper'

module Travis::Api::App::Helpers
  describe Accept do
    class FakeApp < Struct.new(:env)
      include Accept
    end

    it 'returns accept entries sorted properly' do
      accept = "text/html; q=0.2; level=1, application/vnd.travis-ci.2+json, text/*, text/html;level=2; q=0.5"
      FakeApp.new('HTTP_ACCEPT' => accept).accept_entries.map(&:to_s).should ==
        ["application/vnd.travis-ci.2+json; q=1", "text/*; q=1", "text/html; q=0.5; level=2", "text/html; q=0.2; level=1"]
    end

    it 'properly parses params, quality and version' do
      accept = "application/vnd.travis-ci.2+json; q=0.2; level=1; foo=bar"
      accept_entry = FakeApp.new('HTTP_ACCEPT' => accept).accept_entries.first
      accept_entry.quality.should == 0.2
      accept_entry.params.should == { 'level' => '1', 'foo' => 'bar' }
      accept_entry.mime_type.should == 'application/json'
      accept_entry.version.should == '2'
    end

    it 'returns */* for empty accept header' do
      accept_entry = FakeApp.new({}).accept_entries.first
      accept_entry.mime_type.should == '*/*'
    end
  end
end
