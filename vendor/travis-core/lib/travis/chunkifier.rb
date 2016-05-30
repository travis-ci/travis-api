require 'coder/cleaner/simple/encodings'

module Travis
  class Chunkifier < Struct.new(:content, :chunk_size, :options)
    include Enumerable
    include Coder::Cleaner::Simple::Encodings::UTF_8

    def initialize(*)
      super

      self.options ||= {}
    end

    def json?
      options[:json]
    end

    def length
      parts.length
    end

    def each(&block)
      parts.each(&block)
    end

    def parts
      @parts ||= split
    end

    def split
      parts = content.scan(/.{1,#{chunk_split_size}}/m)
      chunks = []
      current_chunk = ''

      parts.each do |part|
        if too_big?(current_chunk + part)
          chunks << current_chunk
          current_chunk = part
        else
          current_chunk << part
        end
      end

      chunks << current_chunk if current_chunk.length > 0

      chunks
    end

    def chunk_split_size
      size = chunk_size / 10
      size == 0 ? 1 : size
    end

    def too_big?(current_chunk)
      current_chunk = current_chunk.to_json if json?
      current_chunk.bytesize > chunk_size
    end
  end
end
