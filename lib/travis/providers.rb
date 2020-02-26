module Travis
  module Providers
    module_function

    def get(vcs_type)
      if vcs_type.downcase.include?('github')
        Travis::Providers::Github
      else
        Travis::Providers::Unknown
      end
    end
  end
end