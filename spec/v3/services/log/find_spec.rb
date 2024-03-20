require 'spec_helper'

describe Travis::API::V3::Services::Log::Find, set_app: true do
  let(:user)        { FactoryBot.create(:user) }
  let(:repo)        { FactoryBot.create(:repository, owner_name: user.login, name: 'minimal', owner: user)}
  let(:build)       { FactoryBot.create(:build, repository: repo) }
  let(:perm)        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true)}
  let(:job)         { Travis::API::V3::Models::Job.create(build: build, started_at: Time.now - 10.days, repository: repo) }
  let(:job2)        { Travis::API::V3::Models::Job.create(build: build, started_at: Time.now - 10.days, repository: repo)}
  let(:job3)        { Travis::API::V3::Models::Job.create(build: build, started_at: Time.now - 10.days, repository: repo)}
  let(:s3job)       { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 10.days) }
  let(:s3job2)       { Travis::API::V3::Models::Job.create(build: build, started_at: Time.now - 10.days, repository: repo) }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:parsed_body) { JSON.load(body) }
  let(:s3log)       { Travis::RemoteLog.new(job_id: s3job.id, content: 'minimal log 1') }
  let(:find_log)    { "string" }
  let(:time)        { Time.now }
  let(:archived_content) { "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch" }
  let(:xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
      <Contents>
          <Key>jobs/#{s3job.id}/log.txt</Key>
          <LastModified>2009-10-12T17:50:30.000Z</LastModified>
          <ETag>&quot;hgb9dede5f27731c9771645a39863328&quot;</ETag>
          <Size>20308738</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
          <Body>#{archived_content} pupa
          </Body>
      </Contents>
    </ListBucketResult>"
  }

  let :log_from_api do
    {
      aggregated_at: Time.now,
      archive_verified: true,
      archived_at: Time.now,
      archiving: false,
      content: 'hello world. this is a really cool log',
      created_at: Time.now,
      id: 345,
      job_id: s3job.id,
      purged_at: Time.now,
      removed_at: Time.now,
      removed_by_id: 45,
      updated_at: Time.now
    }
  end

  let(:json_log_from_api) { log_from_api.to_json }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    allow_any_instance_of(Travis::API::V3::AccessControl::LegacyToken).to receive(:visible?).and_return(true)
    stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
      to_return(:status => 200, :body => xml_content, :headers => {})
    stub_request(:get, %r(https://s3.us-east-2.amazonaws.com/archive.travis-ci.org/?encoding-type=url&prefix=jobs)).
      to_return(status: 200, body: xml_content, headers: {})

    stub_request(:get, "https://s3.us-east-2.amazonaws.com/archive.travis-ci.org/?encoding-type=url&prefix=jobs/#{s3job.id}/log.txt").
      to_return(status: 200, body: xml_content, headers: {})
    stub_request(:get, "https://s3.us-east-2.amazonaws.com/archive.travis-ci.org/jobs/#{s3job.id}/log.txt").
      to_return(status: 200, body: archived_content, headers: {})
#    s3 = Aws::S3::Client.new(stub_responses: true)
#    s3.stub_responses(:list_objects, { contents: [{ key: "jobs/#{s3job.id}/log.txt" }] })
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_by_job_id).and_return(Travis::RemoteLog.new(log_from_api))
  end

  around(:each) do |example|
    options = Travis.config.log_options
    Travis.config.log_options.s3 = { access_key_id: 'key', secret_access_key: 'secret' }
    example.run
    Travis.config.log_options = options
  end

  context 'without authentication' do
    let(:headers) { {} }

    describe 'when repo is public' do
      before { repo.update(private: false) }
      before { s3log.job.update(private: false) }

      it 'returns the log' do
        get("/v3/job/#{s3log.job.id}/log", {}, headers)
        expect(parsed_body['@type']).to eq('log')
        expect(parsed_body['id']).to eq(log_from_api[:id])
      end

      it 'returns the text version of the log' do
        get("/v3/job/#{s3log.job.id}/log.txt", {}, headers)
        expect(last_response.headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(archived_content)
      end
    end

    describe 'when in enterprise mode' do
      before { Travis.config.enterprise = true }
      after { Travis.config.enterprise = false }

      it 'returns the text version of the log with log token supplied' do
        get("/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_AUTHORIZATION' => "token #{token}", 'HTTP_TRAVIS_API_VERSION' => '3'))
        raw_log_href = parsed_body['@raw_log_href']
        expect(raw_log_href).to match(%r{/v3/job/#{s3log.job.id}/log\.txt\?log\.token=})

        get(raw_log_href, {}, headers)
        expect(last_response.headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(archived_content)
      end
    end

    describe 'when repo is private' do
      before { repo.update(private: true) }
      before { s3log.job.update(private: true) }

      it 'returns the text version of the log with log token supplied' do
        get("/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_AUTHORIZATION' => "token #{token}", 'HTTP_TRAVIS_API_VERSION' => '3'))
        raw_log_href = parsed_body['@raw_log_href']
        expect(raw_log_href).to match(%r{/v3/job/#{s3log.job.id}/log\.txt\?log\.token=})
        get(raw_log_href, {}, headers)
        expect(last_response.headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(archived_content)
      end

      it 'returns an error if wrong token is used' do
        get("/v3/job/#{s3log.job.id}/log?log.token=foo", {}, headers)
        expect(last_response.status).to eq(404)
        expect(parsed_body).to eq({
          '@type'=>'error',
          'error_type'=>'not_found',
          'error_message'=>'log not found (or insufficient access)',
          'resource_type'=>'log'
        })
      end

      it 'returns an error' do
        get("/v3/job/#{s3log.job.id}/log", {}, headers)
        expect(last_response.status).to eq(404)
        expect(parsed_body).to eq({
          '@type'=>'error',
          'error_type'=>'not_found',
          'error_message'=>'log not found (or insufficient access)',
          'resource_type'=>'log'
        })
      end
    end
  end

  context 'when log not found in db but stored on S3' do
    describe 'returns log with an array of Log Parts' do

      let(:authorization) { { 'permissions' => ['repository_log_view'] } }
      example do

        s3log.attributes.merge!(archived_at: time, archive_verified: true)
        get("/v3/job/#{s3log.job.id}/log", {}, headers)

        expect(parsed_body).to eq(
          '@type' => 'log',
          '@href' => "/v3/job/#{s3job.id}/log",
          '@representation' => 'standard',
          '@raw_log_href' => "/v3/job/#{s3job.id}/log.txt",
          '@permissions' => {
            'read' => true,
            'debug' => false,
            'cancel' => false,
            'restart' => false,
            'delete_log' => false,
            'view_log' => true
          },
          'id' => log_from_api[:id],
          'content' => archived_content,
          'log_parts' => [
            {
              'content' => archived_content,
              'final' => true,
              'number' => 0
            }
          ]
        )
      end
    end

    describe 'returns log as plain text' do
      example do
        s3log.attributes.merge!(archived_at: Time.now, archive_verified: true)
        get("/v3/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
        expect(last_response.headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(archived_content)
      end
    end

    describe 'it returns the correct content type' do
      example do
        s3log.attributes.merge!(archived_at: Time.now, archive_verified: true)
        get("/v3/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'fun/times'))
        expect(last_response.headers).to include('Content-Type' => 'application/json')
      end
    end

    context 'with authentication and new settings' do
      context 'when public repo' do
        before { repo.update(private: false) }

        context 'when access to old logs is not allowed and write/push setting is off' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, false)
            user_settings.update(:job_log_access_based_limit, false)
          end

          context 'unauthenticated user' do
            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, { 'HTTP_ACCEPT' => 'text/plain' })
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'does not return log' do
                get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
                expect(parsed_body).to eq({
                  '@type'=>'error',
                  'error_type'=>'log_expired',
                  'error_message'=>"We're sorry, but this data is not available anymore. Please check the repository settings in Travis CI."
                })
              end
            end
          end
        end

        context 'when access to old logs is not allowed and write/push setting is on' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, false)
            user_settings.update(:job_log_access_based_limit, true)
          end

          context 'unauthenticated user' do
            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'log_access_denied',
                'error_message'=>"We're sorry, but this data is not available. Please check the repository settings in Travis CI."
              })
            end
          end

          context 'authenticated user read' do
            before { perm.update!(push: false) }

            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'log_access_denied',
                'error_message'=>"We're sorry, but this data is not available. Please check the repository settings in Travis CI."
              })
            end
          end

          context 'authenticated user write' do
            before { perm.update!(push: true) }

            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'does not return log' do
                get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
                expect(parsed_body).to eq({
                  '@type'=>'error',
                  'error_type'=>'not_found',
                  'error_type'=>'log_expired',
                  'error_message'=>"We're sorry, but this data is not available anymore. Please check the repository settings in Travis CI."
                })
              end
            end
          end
        end

        context 'when access to old logs is allowed and write/push setting is on' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, true)
            user_settings.update(:job_log_access_based_limit, true)
          end

          context 'unauthenticated user' do
            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'log_access_denied',
                'error_message'=>"We're sorry, but this data is not available. Please check the repository settings in Travis CI."
              })
            end
          end

          context 'authenticated user read' do
            before { perm.update!(push: false) }

            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'log_access_denied',
                'error_message'=>"We're sorry, but this data is not available. Please check the repository settings in Travis CI."
              })
            end
          end

          context 'authenticated user write' do
            before { perm.update!(push: true) }

            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'returns the log' do
                get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
                expect(last_response.headers).to include('Content-Type' => 'text/plain')
                expect(body).to eq(archived_content)
              end
            end
          end
        end

        context 'when access to old logs is allowed and write/push setting is off' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, true)
            user_settings.update(:job_log_access_based_limit, false)
          end

          context 'unauthenticated user' do
            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, { 'HTTP_ACCEPT' => 'text/plain' })
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'returns the log' do
                get("/v3/job/#{s3job.id}/log", {}, { 'HTTP_ACCEPT' => 'text/plain' })
                expect(last_response.headers).to include('Content-Type' => 'text/plain')
                expect(body).to eq(archived_content)
              end
            end
          end
        end
      end

      context 'when private repo' do
        before { repo.update(private: true) }

        context 'when access to old logs is not allowed and write/push setting is off' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, false)
            user_settings.update(:job_log_access_based_limit, false)
          end

          context 'unauthenticated user' do
            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'not_found',
                'error_message'=>'log not found (or insufficient access)',
                'resource_type'=>'log'
              })
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'does not return log' do
                get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
                expect(parsed_body).to eq({
                  '@type'=>'error',
                  'error_type'=>'not_found',
                  'error_message'=>'log not found (or insufficient access)',
                  'resource_type'=>'log'
                })
              end
            end
          end
        end

        context 'when access to old logs is not allowed and write/push setting is on' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, false)
            user_settings.update(:job_log_access_based_limit, true)
          end

          context 'unauthenticated user' do
            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'not_found',
                'error_message'=>'log not found (or insufficient access)',
                'resource_type'=>'log'
              })
            end
          end

          context 'authenticated user read' do
            before { perm.update!(push: false) }

            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'log_access_denied',
                'error_message'=>"We're sorry, but this data is not available. Please check the repository settings in Travis CI."
              })
            end
          end

          context 'authenticated user write' do
            before { perm.update!(push: true) }

            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'does not return log' do
                get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
                expect(parsed_body).to eq({
                  '@type'=>'error',
                  'error_type'=>'not_found',
                  'error_type'=>'log_expired',
                  'error_message'=>"We're sorry, but this data is not available anymore. Please check the repository settings in Travis CI."
                })
              end
            end
          end
        end

        context 'when access to old logs is allowed and write/push setting is on' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, true)
            user_settings.update(:job_log_access_based_limit, true)
          end

          context 'unauthenticated user' do
            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  { 'HTTP_ACCEPT' => 'text/plain' })
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'not_found',
                'error_message'=>'log not found (or insufficient access)',
                'resource_type'=>'log'
              })
            end
          end

          context 'authenticated user read' do
            before { perm.update!(push: false) }

            it 'does not return log' do
              get("/v3/job/#{s3job.id}/log", {},  headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(parsed_body).to eq({
                '@type'=>'error',
                'error_type'=>'log_access_denied',
                'error_message'=>"We're sorry, but this data is not available. Please check the repository settings in Travis CI."
              })
            end
          end

          context 'authenticated user write' do
            before { perm.update!(push: true) }

            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'returns the log' do
                get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
                expect(last_response.headers).to include('Content-Type' => 'text/plain')
                expect(body).to eq(archived_content)
              end
            end
          end
        end

        context 'when access to old logs is allowed and write/push setting is off' do
          before do
            user_settings = Travis::API::V3::Models::Repository.find(repo.id).user_settings
            user_settings.user = user
            user_settings.change_source = 'travis-api'
            user_settings.update(:job_log_time_based_limit, true)
            user_settings.update(:job_log_access_based_limit, false)
          end

          context 'authenticated user' do
            it 'returns the log' do
              get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
              expect(last_response.headers).to include('Content-Type' => 'text/plain')
              expect(body).to eq(archived_content)
            end

            context 'old log' do
              let(:s3job) { Travis::API::V3::Models::Job.create(build: build, repository: repo, started_at: Time.now - 1000.days) }
  
              it 'returns the log' do
                get("/v3/job/#{s3job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
                expect(last_response.headers).to include('Content-Type' => 'text/plain')
                expect(body).to eq(archived_content)
              end
            end
          end
        end
      end
    end
  end
end
