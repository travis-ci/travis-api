require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Repository < Renderer::ModelRenderer
    representation(:minimal,  :id, :slug)
    representation(:standard, :id, :name, :slug, :description, :github_language, :active, :private, :owner, :last_build, :default_branch)

    def active
      !!model.active
    end

    def owner
      return model.owner if include_owner?
      owner_href = Renderer.href(owner_type.to_sym, id: model.owner_id, script_name: script_name)

      if included_owner? and owner_href
        { :@href => owner_href }
      else
        result = { :@type => owner_type, :id => model.owner_id, :login => model.owner_name }
        result[:@href] = owner_href if owner_href
        result
      end
    end

    def include_owner?
      return false if included_owner?
      return true  if include? 'repository.owner'.freeze
      return true  if include.any? { |i| i.start_with? owner_type or i.start_with? 'owner'.freeze }
    end

    def included_owner?
      included.any? { |i| i.is_a? Model and i.class.polymorphic_name == model.owner_type and i.id == model.owner_id }
    end

    def owner_type
      @owner_type ||= model.owner_type.downcase if model.owner_type
    end

    def last_build
      return nil unless model.last_build_id
      return model.last_build if include_last_build?
      {
        :@type        => 'build'.freeze,
        :@href        => Renderer.href(:build, script_name: script_name, id: model.last_build_id),
        :id           => model.last_build_id,
        :number       => model.last_build_number,
        :state        => model.last_build_state.to_s,
        :duration     => model.last_build_duration,
        :started_at   => model.last_build_started_at,
        :finished_at  => model.last_build_finished_at,
      }
    end

    def include_last_build?
      return true if include? 'repository.last_build'.freeze
      return true if include.any?  { |i| i.start_with? 'build.'.freeze }
      return true if included.any? { |i| i.is_a? Models::Build and i.id == model.last_build_id }
    end
  end
end
