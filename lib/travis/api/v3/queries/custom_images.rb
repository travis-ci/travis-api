module Travis::API::V3
  class Queries::CustomImages < Query
    def for_owner(owner)
      Models::CustomImage.available.where(owner_id: owner.id, owner_type: owner_type(owner)).order('created_at DESC')
    end

    def delete(image_ids, owner, sender)
      client = ArtifactManagerClient.new(sender.id)
      client.delete_images(owner_type(owner), owner.id, image_ids)
    end

    def usage(owner, user_id, from, to)
      client = BillingClient.new(user_id)
      client.storage_usage(owner_type(owner), owner.id, from, to)
    end

    private

    def owner_type(owner)
      owner.vcs_type =~ /User/ ? 'User' : 'Organization'
    end
  end
end
