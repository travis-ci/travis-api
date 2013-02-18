require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Accept
      HEADER_FORMAT   = /vnd\.travis-ci\.(\d+)\+(\w+)/
      DEFAULT_VERSION = 'v1'
      DEFAULT_FORMAT  = 'json'

      class Entry
        SEPARATORS = Regexp.escape("()<>@,;:\/[]?={}\t ")
        TOKEN      = /[^#{SEPARATORS}]+/
        attr_reader :type, :subtype, :quality, :version, :params
        def initialize(accept_string)
          @type, @subtype, @quality, @version, @params = parse(accept_string)
        end

        def <=>(other)
          [1 - quality, mime_type.count('*'), 1 - params.size] <=>
            [1 - other.quality, other.mime_type.count('*'), 1 - other.params.size]
        end

        def mime_type
          "#{type}/#{subtype}"
        end

        def version
          version = @version || params['version']
          version ? "v#{version}" : nil
        end

        def accepts?(mime_type)
          return true if self.mime_type == '*/*'

          type, subtype = mime_type.scan(%r{(#{TOKEN})/(#{TOKEN})}).flatten
          type == self.type && (self.subtype == '*' || subtype == self.subtype)
        end

        def to_s
          str = "#{mime_type}; q=#{quality}"
          str << "; #{params.map { |k,v| "#{k}=#{v}" }.join('; ')}" if params.length > 0
          str
        end

        private
        def parse(str)
          # this handles only subset of what Accept header can
          # contain, only the simplest cases, no quoted strings etc.
          type, subtype, params = str.scan(%r{(#{TOKEN})/(#{TOKEN})(.*)}).flatten
          quality = 1

          version = nil
          if params
            params = Hash[*params.split(';').map { |p| p.scan /(#{TOKEN})=(#{TOKEN})/ }.flatten]
            quality = params.delete('q').to_f if params['q']
          end

          if subtype =~ HEADER_FORMAT
            subtype = $2
            version = $1
          end

          [type, subtype, quality, version, params]
        end
      end

      def accept_entries
        entries = env['HTTP_ACCEPT'].to_s.delete(' ').to_s.split(',').map { |e| Entry.new(e) }
        entries.empty? ? [Entry.new('*/*')] : entries.sort
      end

      def acceptable_formats
        if format = env['travis.format_from_path']
          [Entry.new(Rack::Mime.mime_type(".#{format}"))]
        else
          accept_entries
        end
      end

      def accept_version
        @accept_version ||= request.accept.join =~ HEADER_FORMAT && "v#{$1}" || DEFAULT_VERSION
      end

      def accept_format
        @accept_format ||= request.accept.join =~ HEADER_FORMAT && $2 || DEFAULT_FORMAT
      end
    end
  end
end
