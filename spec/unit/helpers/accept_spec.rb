module Travis::Api::App::Helpers
  describe Accept do
    class FakeApp < Struct.new(:env)
      include Accept
    end

    it 'returns accept entries sorted properly' do
      accept = "text/html; q=0.2; level=1, application/vnd.travis-ci.2+json, text/*, text/html;level=2; q=0.5"
      expect(FakeApp.new({'HTTP_ACCEPT' => accept}).accept_entries.map(&:to_s)).to eq(
        ["application/json; q=1", "text/*; q=1", "text/html; q=0.5; level=2", "text/html; q=0.2; level=1"]
      )
    end

    it 'properly parses params, quality and version' do
      accept = "application/vnd.travis-ci.2+json; q=0.2; level=1; foo=bar"
      accept_entry = FakeApp.new({'HTTP_ACCEPT' => accept}).accept_entries.first
      expect(accept_entry.quality).to eq(0.2)
      expect(accept_entry.params).to eq({ 'level' => '1', 'foo' => 'bar' })
      expect(accept_entry.mime_type).to eq('application/json')
      expect(accept_entry.version).to eq('v2')
    end

    it 'returns */* for empty accept header' do
      accept_entry = FakeApp.new({}).accept_entries.first
      expect(accept_entry.mime_type).to eq('*/*')
    end

    it 'accepts text/plain when chunked is preferred' do
      app = FakeApp.new({'HTTP_ACCEPT' => %w(
        application/json; chunked=true; version=2,
        application/json; version=2,
        text/plain
      ).join(' ')})

      expect(app.accepts?('text/plain')).to eq(true)
    end

    describe Accept::Entry do
      describe 'version' do
        it 'can be passed as a vendor extension' do
          entry = Accept::Entry.new('application/vnd.travis-ci.2+json')
          expect(entry.version).to eq('v2')
        end

        it 'can be passed as a param' do
          entry = Accept::Entry.new('application/json; version=2')
          expect(entry.version).to eq('v2')
        end

        it 'has a higher priority when in vendor extension' do
          entry = Accept::Entry.new('application/vnd.travis-ci.1+json; version=2')
          expect(entry.version).to eq('v1')
        end
      end

      describe 'accepts?' do
        it 'accepts everything with */* type' do
          entry = Accept::Entry.new('*/*')
          expect(entry.accepts?('application/json')).to eq(true)
          expect(entry.accepts?('foo/bar')).to eq(true)
        end

        it 'accepts every subtype with application/* type' do
          entry = Accept::Entry.new('application/*')

          expect(entry.accepts?('application/foo')).to eq(true)
          expect(entry.accepts?('application/bar')).to eq(true)
          expect(entry.accepts?('text/plain')).to eq(false)
        end

        it 'accepts when type and subtype match' do
          entry = Accept::Entry.new('application/json')

          expect(entry.accepts?('application/json')).to eq(true)
          expect(entry.accepts?('application/xml')).to eq(false)
        end
      end
    end
  end
end
