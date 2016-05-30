require 'gh'
require 'travis/services/base'
require 'travis/model/request/approval'
require 'travis/notification/instrument'
require 'travis/advisory_locks'
require 'travis/travis_yml_stats'

module Travis
  module Requests
    module Services
      class Receive < Travis::Services::Base
        require 'travis/requests/services/receive/api'
        require 'travis/requests/services/receive/cron'
        require 'travis/requests/services/receive/pull_request'
        require 'travis/requests/services/receive/push'

        extend Travis::Instrumentation

        class PayloadValidationError < StandardError; end

        register :receive_request

        class << self
          def payload_for(type, data)
            data = GH.load(data)
            const_get(type.camelize).new(data)
          end
        end

        attr_reader :request, :accepted

        def run
          with_transactional_advisory_lock do
            if accept?
              create && start
              store_config_info if verify
            else
              rejected
            end
            request
          end
        rescue GH::Error => e
          Travis.logger.error "payload for #{slug} could not be received as GitHub returned a #{e.info[:response_status]}: #{e.info}, github-guid=#{github_guid}, event-type=#{event_type}"
        end
        instrument :run

        def accept?
          payload.validate!
          validate!
          @accepted = payload.accept?
        rescue PayloadValidationError => e
          Travis.logger.error "#{e.message}, github-guid=#{github_guid}, event-type=#{event_type}"
          @accepted = false
        end

        private

          def with_transactional_advisory_lock
            return yield unless payload.repository
            result = nil
            Travis::AdvisoryLocks.exclusive("receive-repo:#{payload.repository[:github_id]}", 300) do
              ActiveRecord::Base.connection.transaction do
                result = yield
              end
            end
            result
          rescue => e
            ActiveRecord::Base.connection.rollback_db_transaction
            raise
          end

          def validate!
            repo_not_found! unless repo
            verify_owner
          end

          def verify_owner
            owner = owner_by_payload
            owner_not_found! unless owner
            update_owner(owner) if owner.id != repo.owner_id && !api_request?
          end

          def create
            @request = repo.requests.create!(payload.request.merge(
              :payload => params[:payload],
              :event_type => event_type,
              :state => :created,
              :commit => commit,
              :owner => repo.owner,
              :token => params[:token]
            ))
          end

          def start
            request.start!
          end

          def verify
            request.reload
            if request.builds.count == 0
              approval = Request::Approval.new(request)
              Travis.logger.warn("[request:receive] Request #{request.id} commit=#{request.commit.try(:commit).inspect} didn't create any builds: #{approval.result}/#{approval.message}")
              false
            elsif !request.creates_jobs?
              approval = Request::Approval.new(request)
              Travis.logger.warn("[request:receive] Request #{request.id} commit=#{request.commit.try(:commit).inspect} didn't create any job: #{approval.result}/#{approval.message}")
              false
            else
              Travis.logger.info("[request:receive] Request #{request.id} commit=#{request.commit.try(:commit).inspect} created #{request.builds.count} builds")
              true
            end
          end

          def update_owner(owner)
            repo.update_attributes!(owner: owner, owner_name: owner.login)
            owner_updated
          end

          def owner_by_payload
            if id = payload.repository[:owner_id]
              lookup_owner(payload.repository[:owner_type], id: id)
            elsif github_id = payload.repository[:owner_github_id]
              lookup_owner(payload.repository[:owner_type], github_id: github_id)
            elsif login = payload.repository[:owner_name]
              lookup_owner(%w(User Organization), login: login)
            end
          end

          def lookup_owner(types, attrs)
            Array(types).map(&:constantize).each do |type|
              owner = type.where(attrs).first
              return owner if owner
            end
            nil
          end

          def repo_not_found!
            Travis::Metrics.meter('request.receive.repository_not_found')
            raise PayloadValidationError, "Repository not found: #{payload.repository.slice(:id, :github_id, :owner_name, :name)}"
          end

          def owner_not_found!
            Travis::Metrics.meter('request.receive.repository_owner_not_found')
            raise PayloadValidationError, "The given repository owner could not be found: #{payload.repository.slice(:owner_id, :owner_github_id, :owner_type, :owner_name).inspect}"
          end

          def owner_updated
            Travis::Metrics.meter('request.receive.update_owner')
            Travis.logger.warn("[request:receive] Repository owner updated for #{slug}: #{repo.owner_type}##{repo.owner_id} (#{repo.owner_name})")
          end

          def rejected
            commit = payload.commit['commit'].inspect if payload.commit rescue nil
            Travis.logger.info("[request:receive] Github event rejected: event_type=#{event_type.inspect} repo=\"#{slug}\" commit=#{commit} action=#{payload.action.inspect}")
          end

          def payload
            @payload ||= self.class.payload_for(event_type, params[:payload])
          end

          def github_guid
            params[:github_guid]
          end

          def event_type
            @event_type ||= (params[:event_type] || 'push').gsub('-', '_')
          end

          def api_request?
            event_type == 'api'
          end

          def repo
            @repo ||= run_service(:find_repo, payload.repository)
          end

          def slug
            payload.repository ? payload.repository.values_at(:owner_name, :name).join('/') : '?'
          end

          def commit
            @commit ||= repo.commits.create!(payload.commit) if payload.commit
          end

          def store_config_info
            Travis::TravisYmlStats.store_stats(request)
          rescue => e
            Travis.logger.warn("[request:receive] Couldn't store .travis.yml stats: #{e.message}")
            Travis::Exceptions.handle(e)
          end

          class Instrument < Notification::Instrument
            def run_completed
              params = target.params
              publish(
                :msg => "type=#{params[:event_type].inspect}",
                :type => params[:event_type],
                :accept? => target.accepted,
                :payload => params[:payload]
              )
            end
          end
          Instrument.attach_to(self)
      end
    end
  end
end
