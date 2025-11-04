# frozen_string_literal: true

require 'travis/remote_vcs/repository'
require 'travis/remote_vcs/organization'

module Travis
  module Services
    class AssemblaNotifyService
      VALID_ACTIONS = %w[restrict restore].freeze
      VALID_OBJECTS = %w[space tool].freeze

      def initialize(payload)
        @action = payload[:action]
        @object = payload[:object]
        @object_id = payload[:id]
      end

      def run
        return false unless validate

        case @object
        when 'tool'
          handle_tool_action
        when 'space'
          handle_space_action
        else
          false
        end
      end

      private

      def validate
        unless VALID_ACTIONS.include?(@action)
          Travis.logger.error("Invalid action: #{@action}. Allowed actions: #{VALID_ACTIONS.join(', ')}")
          return false
        end

        unless VALID_OBJECTS.include?(@object)
          Travis.logger.error("Invalid object type: #{@object}. Allowed objects: #{VALID_OBJECTS.join(', ')}")
          return false
        end

        true
      end

      def handle_tool_action
        vcs_repository = Travis::RemoteVCS::Repository.new
        case @action
        when 'restrict'
          vcs_repository.destroy(repository_id: @object_id, vcs_type: 'AssemblaRepository')
        when 'restore'
          vcs_repository.restore(repository_id: @object_id)
        end
      end

      def handle_space_action
        vcs_organization = Travis::RemoteVCS::Organization.new
        case @action
        when 'restrict'
          vcs_organization.destroy(org_id: @object_id)
        when 'restore'
          vcs_organization.restore(org_id: @object_id)
        end
      end
    end
  end
end
