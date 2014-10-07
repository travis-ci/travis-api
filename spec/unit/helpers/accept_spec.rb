require 'spec_helper'

module Travis::Api::App::Helpers
  describe Accept do
    class FakeApp < Struct.new(:env)
      include Accept
    end

    it 'returns accept entries sorted properly' do
      accept = "text/html; q=0.2; level=1, application/vnd.travis-ci.2+json, text/*, text/html;level=2; q=0.5"
      FakeApp.new('HTTP_ACCEPT' => accept).accept_entries.map(&:to_s).should ==
        ["application/json; q=1", "text/*; q=1", "text/html; q=0.5; level=2", "text/html; q=0.2; level=1"]
    end

    it 'properly parses params, quality and version' do
      accept = "application/vnd.travis-ci.2+json; q=0.2; level=1; foo=bar"
      accept_entry = FakeApp.new('HTTP_ACCEPT' => accept).accept_entries.first
      accept_entry.quality.should == 0.2
      accept_entry.params.should == { 'level' => '1', 'foo' => 'bar' }
      accept_entry.mime_type.should == 'application/json'
      accept_entry.version.should == 'v2'
    end

    it 'returns */* for empty accept header' do
      accept_entry = FakeApp.new({}).accept_entries.first
      accept_entry.mime_type.should == '*/*'
    end

    describe Accept::Entry do
      describe 'version' do
        it 'can be passed as a vendor extension' do
          entry = Accept::Entry.new('application/vnd.travis-ci.2+json')
          entry.version.should == 'v2'
        end

        it 'can be passed as a param' do
          entry = Accept::Entry.new('application/json; version=2')
          entry.version.should == 'v2'
        end

        it 'has a higher priority when in vendor extension' do
          entry = Accept::Entry.new('application/vnd.travis-ci.1+json; version=2')
          entry.version.should == 'v1'
        end
      end

      describe 'accepts?' do
        it 'accepts everything with */* type' do
          entry = Accept::Entry.new('*/*')
          entry.accepts?('application/json').should == true
          entry.accepts?('foo/bar').should == true
        end

        it 'accepts every subtype with application/* type' do
          entry = Accept::Entry.new('application/*')

          entry.accepts?('application/foo').should == true
          entry.accepts?('application/bar').should == true
          entry.accepts?('text/plain').should == false
        end

        it 'accepts when type and subtype match' do
          entry = Accept::Entry.new('application/json')

          entry.accepts?('application/json').should == true
          entry.accepts?('application/xml').should == false
        end
      end
    end
  end
end
