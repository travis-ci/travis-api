require 'gh'

module Travis
  module Github
    module Services
      class SyncUser < Travis::Services::Base
        class Organizations
          class Filter
            attr_reader :data, :limit
            def initialize(data, options = {})
              @data = data || {}
              @limit = options[:repositories_limit] || 1000
            end

            def allow?
              repositories_count < limit
            end

            def repositories_count
              # I was not sure how to handle the case where we don't get the
              # sufficient amount of data here and this seems the best answer,
              # that way we will not get orgs siltently ignored
              data['public_repositories'] || 0
            end
          end

          class << self
            def cancel_memberships(user, orgs)
              user.memberships.where(:organization_id => orgs.map(&:id)).delete_all
            end
          end

          extend Travis::Instrumentation
          include Travis::Logging

          attr_reader :user, :data

          def initialize(user)
            @user = user
          end

          def run
            with_github do
              { :synced => create_or_update, :removed => remove }
            end
          end
          instrument :run

          private

            def create_or_update
              fetch_and_filter.map do |data|
                org = create_or_update_org(data)
                user.organizations << org unless user.organizations.include?(org)
                org
              end
            end

            def remove
              orgs = user.organizations.reject { |org| github_ids.include?(org.github_id) }
              self.class.cancel_memberships(user, orgs)
              orgs
            end

            def fetch
              @data ||= GH['user/orgs'].to_a
            end
            instrument :fetch, :level => :debug

            def github_ids
              @github_ids ||= data.map { |org| org['id'] }
            end

            def with_github(&block)
              # TODO in_parallel should return the block's result in a future version
              result = nil
              GH.with(:token => user.github_oauth_token) do
                # GH.in_parallel do
                  result = yield
                # end
              end
              result
            end

            def fetch_and_filter
              fetch.map do |data|
                fetch_resource("organizations/#{data['id']}")
              end.find_all do |data|
                options = Travis.config.sync.organizations || {}
                Filter.new(data, options).allow?
              end
            end

            def fetch_resource(resource)
              GH[resource] # TODO should be: ?type=#{self.class.type} but GitHub doesn't work as documented
            rescue GH::Error => e
              log_exception(e)
            end

            def create_or_update_org(data)
              org = Organization.find_or_create_by_github_id(data['id'])
              org.update_attributes!({
                :name => data['name'],
                :login => data['login'],
                :email => data['email'],
                :avatar_url => avatar_url(data['_links']['avatar']),
                :location => data['location'],
                :homepage => data['_links']['blog'].try(:fetch, 'href'),
                :company => data['company']
              })
              org
            end

            def avatar_url(github_data)
              href = github_data.try(:fetch, 'href')
              href ? href[/^(https:\/\/[\w\.\/]*)/, 1] : nil
            end

            class Instrument < Notification::Instrument
              def run_completed
                format = lambda do |orgs|
                  orgs.map { |org| { id: org.id, login: org.login } }
                end

                publish(
                  msg: %(for #<User id=#{target.user.id} login="#{target.user.login}">),
                  result: { synced: format.call(result[:synced]), removed: format.call(result[:removed]) }
                )
              end

              def fetch_completed
                publish(
                  msg: %(for #<User id=#{target.user.id} login="#{target.user.login}">),
                  result: result
                )
              end
            end
            Instrument.attach_to(self)
        end
      end
    end
  end
end
