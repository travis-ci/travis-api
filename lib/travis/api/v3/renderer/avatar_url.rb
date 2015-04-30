require 'digest/md5'

module Travis::API::V3
  module Renderer::AvatarURL
    GRAVATAR_URL = 'https://0.gravatar.com/avatar/%s'
    private_constant :GRAVATAR_URL

    extend self

    def avatar_url(object = @model)
      case object
      when has(:avatar_url)   then object.avatar_url
      when has(:gravatar_url) then object.gravatar_url
      when has(:gravatar_id)  then GRAVATAR_URL % object.gravatar_id
      when has(:email)        then GRAVATAR_URL % Digest::MD5.hexdigest(object.email)
      when String             then GRAVATAR_URL % Digest::MD5.hexdigest(object)
      end
    end

    def has(field)
      proc { |o| o.respond_to?(field) and o.send(field).present? }
    end

    private :has
  end
end
