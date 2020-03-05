module Travis::API::V3
  module Models::JsonSync
    attr_reader :parent, :attr

    def sync(parent, attr)
      @parent, @attr = parent, attr
      @sync = -> do

        if attr
          previous = @parent.send(@attr) || {}
          @parent[@attr] = previous.merge(to_h)
          @parent.save!
        end
      end
    end

    def sync_once(*args)
      sync(*args)
      sync!
    end

    def sync!
      @sync.call if @sync
    end

    def to_h
      raise NotImplementedError
    end
  end
end
