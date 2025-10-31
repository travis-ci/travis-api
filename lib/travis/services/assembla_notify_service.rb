# frozen_string_literal: true

require 'travis/remote_vcs/repository'
require 'travis/remote_vcs/organization'

module Travis
  module Services
    class AssemblaNotifyService
      VALID_ACTIONS = %w[destroy].freeze
      VALID_OBJECTS = %w[space tool].freeze

      def initialize(payload)
        Travis.logger.info(payload.inspect)
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
          Travis.logger.info("============ Unsupported object type for destruction ============")
          { status: 400, body: { error: 'Unsupported object type for destruction' } }
        end
      end

      private

      def validate
        Travis.logger.info("============ In Assembla notification service ============")
        unless VALID_ACTIONS.include?(@action)
          Travis.logger.info("============ invalid action #{@action} ============")
          return { status: 400, body: { error: 'Invalid action', allowed_actions: VALID_ACTIONS } }
        end

        unless VALID_OBJECTS.include?(@object)
          Travis.logger.info("============ invalid object type #{@object} ============")
          return { status: 400, body: { error: 'Invalid object type', allowed_objects: VALID_OBJECTS } }
        end
      end

      def handle_tool_destruction
        Travis.logger.info("============ in handle_tool_destruction ============")
        vcs_repository = Travis::RemoteVCS::Repository.new
        vcs_repository.destroy(repository_id: @object_id)
      end

      def handle_space_destruction
        Travis.logger.info("============ in handle_space_destruction ============")
        vcs_organization = Travis::RemoteVCS::Organization.new
        vcs_organization.destroy(org_id: @object_id)
      end
    end
  end
end
