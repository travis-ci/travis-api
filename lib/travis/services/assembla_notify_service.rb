# frozen_string_literal: true

require 'travis/remote_vcs/repository'
require 'travis/remote_vcs/organization'

module Travis
  module Services
    class AssemblaNotifyService
      VALID_ACTIONS = %w[destroy].freeze
      VALID_OBJECTS = %w[space tool].freeze

      def initialize(payload)
        @action = payload[:action]
        @object = payload[:object]
        @object_id = payload[:id]
      end

      def run
        validate
        case @object
        when 'tool'
          handle_tool_destruction
        when 'space'
          handle_space_destruction
        else
          { status: 400, body: { error: 'Unsupported object type for destruction' } }
        end
      end

      private

      def validate
        unless VALID_ACTIONS.include?(@action)
          return { status: 400, body: { error: 'Invalid action', allowed_actions: VALID_ACTIONS } }
        end

        unless VALID_OBJECTS.include?(@object)
          return { status: 400, body: { error: 'Invalid object type', allowed_objects: VALID_OBJECTS } }
        end
      end

      def handle_tool_destruction
        vcs_repository = Travis::RemoteVCS::Repository.new
        vcs_repository.destroy(repository_id: @object_id)
      rescue => e
        Travis.logger.error("Failed to process Assembla tool destruction: #{e.message}")
      end

      def handle_space_destruction
        vcs_organization = Travis::RemoteVCS::Organization.new
        vcs_organization.destroy(org_id: @object_id)
      rescue => e
        Travis.logger.error("Failed to process Assembla organization destruction: #{e.message}")  
      end
    end
  end
end
