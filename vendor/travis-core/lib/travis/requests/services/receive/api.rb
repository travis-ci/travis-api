module Travis
  module Requests
    module Services
      class Receive < Travis::Services::Base
        class Api
          VALIDATION_ERRORS = {
            repo: 'Repository data is not present in payload',
          }
          attr_reader :event

          def initialize(event)
            @event = event
          end

          def accept?
            true
          end

          def validate!
            error(:repo) if repo_data.nil?
          end

          def action
            nil
          end

          def repository
            @repository ||= {
              owner_id:   repo_data['owner_id'],
              owner_type: repo_data['owner_type'],
              owner_name: repo_data['owner_name'],
              name:       repo_data['name']
            }
          end

          def request
            @request ||= {
              :config => event['config']
            }
          end

          def commit
            @commit ||= {
              commit:          commit_data['sha'],
              message:         message,
              branch:          branch,
              ref:             nil,                                        # TODO verify that we do not need this
              committed_at:    commit_data['commit']['committer']['date'], # TODO in case of API requests we'd want to display the timestamp of the incoming request
              committer_name:  commit_data['commit']['committer']['name'],
              committer_email: commit_data['commit']['committer']['email'],
              author_name:     commit_data['commit']['author']['name'],
              author_email:    commit_data['commit']['author']['email'],
              compare_url:     commit_data['_links']['self']['href']
            }
          end

          private

            def gh
              Github.authenticated(user)
            end

            def user
              @user ||= User.find(event['user']['id'])
            end

            def repo_data
              event['repository'] || {}
            end

            def message
              event['message'] || commit_data['commit']['message']
            end

            def slug
              repo_data.values_at('owner_name', 'name').join('/')
            end

            def branch
              event['branch'] || 'master'
            end

            def repo_github_id
              repo.try(:github_id) || raise(ActiveRecord::RecordNotFound)
            end

            def repo
              if id = repo_data['id']
                Repository.find(id)
              else
                Repository.by_slug(slug).first
              end
            end

            def commit_data
              @commit_data ||= gh["repos/#{slug}/commits?sha=#{branch}&per_page=1"].first # TODO I guess Api would protect against GH errors?
            end

            def error(type)
              raise PayloadValidationError, VALIDATION_ERRORS[type]
            end
        end
      end
    end
  end
end
