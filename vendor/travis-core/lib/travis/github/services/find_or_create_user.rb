require 'gh'
require 'travis/model/repository'
require 'travis/model/user'
require 'travis/model/user/renaming'
require 'travis/services/base'

module Travis
  module Github
    module Services
      class FindOrCreateUser < Travis::Services::Base
        register :github_find_or_create_user

        def run
          find || create
        end

        private

          include ::User::Renaming

          def find
            ::User.where(github_id: params[:github_id]).first.tap do |user|
              if user
                ActiveRecord::Base.transaction do
                  login = params[:login] || data['login']
                  if user.login != login
                    Travis.logger.info("Changing #<User id=#{user.id} login=\"#{user.login}\" github_id=#{user.github_id}> login: current=\"#{user.login}\", new=\"#{login}\" (FindOrCreateUser), data: #{data.inspect}")
                    rename_repos_owner(user.login, login)
                    user.update_attributes(login: login)
                  end
                end

                nullify_logins(user.github_id, user.login)
              end
            end
          end

          def create
            user = User.create!(
              :name => data['name'],
              :login => data['login'],
              :email => data['email'],
              :github_id => data['id'],
              :gravatar_id => data['gravatar_id']
            )

            nullify_logins(user.github_id, user.login)

            user
          rescue ActiveRecord::RecordNotUnique
            find
          end

          def data
            @data ||= fetch_data
          end

          def fetch_data
            data = GH["user/#{params[:github_id]}"] || raise(Travis::GithubApiError)
            Travis.logger.info("Fetching data for github_id=#{params[:github_id]} (FindOrCreateUser), data: #{data.inspect}")
            data
          end
      end
    end
  end
end
