module Travis::API::V3
  class Models::CustomImageLog < Model
    after_initialize :readonly!
    belongs_to :custom_image
  end
end
