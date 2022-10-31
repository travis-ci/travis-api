module Travis::API::V3
  class Renderer::V2Subscriptions < CollectionRenderer
    type           :v2_subscriptions
    collection_key :v2_subscriptions

    def fields
      super.tap do |fields|
        fields[:@permissions] = render_entry(permissions)
      end
    end

    private

    def list
      @list.subscriptions
    end

    def permissions
      @list.permissions
    end
  end
end
