module Travis::API::V3
  class Renderer::Subscriptions < CollectionRenderer
    type           :subscriptions
    collection_key :subscriptions

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
