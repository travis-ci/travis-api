require "addressable/uri"

module Travis::API::V3
  class Paginator
    class URLGenerator
      class FancyParser
        def initialize(href)
          @uri = Addressable::URI.parse(href)
        end

        def generate(offset, limit)
          uri = @uri.dup
          uri.query_values = uri.query_values.merge("offset".freeze => offset, "limit".freeze => limit)
          uri.to_s
        end
      end

      class FastParser
        PATTERN = /\?(?:&?(?:limit|offset)=[^=]*)*\Z/

        def self.can_handle?(href)
          return true unless href.include? ??.freeze
          href =~ PATTERN
        end

        def initialize(href)
          @path_info = href.split(??.freeze, 2).first
        end

        def generate(offset, limit)
          "#{@path_info}?limit=#{limit}&offset=#{offset}"
        end
      end

      def initialize(href, limit: 0, offset: 0, count: 0, **)
        @parser = FastParser.can_handle?(href) ? FastParser.new(href) : FancyParser.new(href)
        @href   = href
        @limit  = limit
        @offset = offset
        @count  = count
      end

      def last?
        @count <= @offset + @limit
      end

      def first?
        @offset == 0
      end

      def next_info
        info(offset: @offset + @limit) unless last?
      end

      def previous_info
        return if @offset == 0
        @offset <= @limit ? info(offset: 0, limit: @offset) : info(offset: @offset - @limit, limit: @limit)
      end

      def first_info
        info(offset: 0)
      end

      def last_info
        offset = @count / @limit * @limit
        offset -= @limit if offset == @count
        info(offset: offset)
      end

      def info(offset: @offset, limit: @limit)
        {
          :@href  => uri_with(offset, limit),
          :offset => offset,
          :limit  => limit
        }
      end

      def to_h
        {
          is_first: first?,
          is_last:  last?,
          next:     next_info,
          prev:     previous_info,
          first:    first_info,
          last:     last_info
        }
      end

      def uri_with(offset, limit)
        return @href if offset == @offset and limit == @limit
        @parser.generate(offset, limit)
      end
    end
  end
end
