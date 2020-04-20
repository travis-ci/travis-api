require 'json'
require 'faraday'

module Travis::API::V3
  class Queries::RequestPreview < Query
    attr_reader :user, :repo

    def expand(user, repo)
      @user, @repo = user, repo
      Models::RequestConfigs.new(body)
    end

    private

      def body
        JSON.parse(resp.body).deep_symbolize_keys
      end

      def resp
        @resp ||= client.post('configs', JSON.dump(data)).tap do |resp|
          handle_errors(resp)
        end
      end

      def data
        data = { repo: repo_data }
        data = data.merge(params)
        data[:ref] ||= repo.default_branch.name
        data[:data] ||= {}
        data[:data][:repo] ||= repo.slug
        data[:data][:fork] ||= repo.fork?
        data[:data][:env] ||= env
        data
      end

      def env
        repo.env_vars.map { |var| { var.name => var.value.decrypt } }
      end

      def repo_data
        {
          github_id: repo.github_id,
          slug: repo.slug,
          token: repo_token,
          private: repo.private?,
          default_branch: repo.default_branch.name,
          allow_config_imports: repo.settings[:allow_config_imports],
          private_key: repo.key&.private_key
        }
      end

      def repo_token
        repo.installation? ? repo.app_token : user.github_oauth_token
      end

      def client
        Faraday.new(config.url, ssl: config.ssl) do |c|
          c.headers['Authorization'] = "internal #{config.token}"
          c.headers['Content-Type'] = 'application/json'
          c.headers['Accept'] = 'application/json'
          c.headers['X-Source'] = 'travis-ci/travis-api'
          c.headers['X-User'] = user.login
          c.adapter :net_http
        end
      end

      def handle_errors(resp)
        case resp.status
        when 400 then raise ClientError, resp.body
        when 401 then raise Error, 'unable to authenticate with Yml'
        when 500 then raise Error, 'Yml application error'
        end
      end

      def params
        only(super.deep_symbolize_keys, :ref, :configs, :data)
      end

      def only(hash, *keys)
        hash.select { |key, _| keys.include?(key) }.to_h
      end

      def config
        Travis.config.yml
      end
  end
end
