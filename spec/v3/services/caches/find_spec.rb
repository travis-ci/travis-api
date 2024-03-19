require 'spec_helper'

describe Travis::API::V3::Services::Caches::Find, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:s3_bucket_name)  { "travis-cache-staging-org" }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:result) { [
    {
      "@type"=>"cache",
      "@representation"=>"standard",
      "repository_id"=>1,
      "size"=>20308738,
      "branch"=>"ha-bug-rm_rf",
      "last_modified"=>"2009-10-12T17:50:30Z",
      "name"=>"cache-linux-precise-lkjdhfsod8fu4tc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-2.2.5--gemfile-Gemfile.tgz",
      "repo"=>{
        "@type"=>"repository",
        "@href"=>"/v3/repo/#{repo.id}",
        "@representation"=>"minimal",
        "id"=>repo.id,
        "name"=>repo.name,
        "slug"=>repo.slug
        }
    },
    {
      "@type"=>"cache",
      "@representation"=>"standard",
      "repository_id"=>1,
      "size"=>64994,
      "branch"=>"master",
      "last_modified"=>"2009-10-12T17:50:30Z",
      "name"=>"cache-linux-precise-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz",
      "repo"=>{
        "@type"=>"repository",
        "@href"=>"/v3/repo/#{repo.id}",
        "@representation"=>"minimal",
        "id"=>repo.id,
        "name"=>repo.name,
        "slug"=>repo.slug
        }
      },
      {
        "@type"=>"cache",
        "@representation"=>"standard",
        "repository_id"=>1,
        "size"=>123,
        "name"=>"cache-osx-xcode8.2-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz",
        "branch"=>"cd-mac-build",
        "last_modified"=>"2009-10-12T17:50:30Z",
        "repo"=> {
          "@type"=>"repository",
          "@href"=>"/v3/repo/1",
          "@representation"=>"minimal",
          "id"=>repo.id, "name"=>repo.name,
          "slug"=>repo.slug
        }
      }
    ]
  }

  let(:gcs_json_response) {
    %q{
      {"kind": "storage#objects",
      "nextPageToken": "string",
      "prefixes": [

      ],
      "items": [
        { "kind": "storage#object",
          "id": "travis-cache-staging-org-gce/25736446/cd-mac-build/cache-osx-xcode8.2-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz/1488893377144168",
          "selfLink":  "https://www.googleapis.com/storage/v1/b/travis-cache-staging-org-gce/o/25736446%2Fcd-mac-build%2Fcache-osx-xcode8.2-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz",
          "name": "25736446/cd-mac-build/cache-osx-xcode8.2-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz",
          "bucket": "travis-cache-production-org-gce",
          "generation": 1,
          "metageneration": 2,
          "contentType": "string",
          "timeCreated": "2009-10-12T17:50:30.000Z",
          "updated": "2009-10-12T17:50:30.000Z",
          "timeDeleted": "2009-10-12T17:50:30.000Z",
          "storageClass": "string",
          "size": 123,
          "md5Hash": "string",
          "mediaLink": "string",
          "contentEncoding": "string",
          "contentDisposition": "string",
          "contentLanguage": "string",
          "cacheControl": "string",
          "metadata": {
            "key": "string"
          },
          "acl": [
          ],
          "owner": {
            "entity": "string",
            "entityId": "string"
          },
          "crc32c": "string",
          "componentCount": 2,
          "etag": "string",
          "customerEncryption": {
            "encryptionAlgorithm": "string",
            "keySha256": "string"
          }
        }
      ]}
    }
  }

  let(:empty_gcs_content) {
    %q{
      {"kind": "storage#objects",
      "nextPageToken": "string",
      "prefixes": [
      ],
      "items": []
    }
    }
  }


  let(:xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>#{s3_bucket_name}</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
      <Contents>
          <Key>#{repo.github_id}/ha-bug-rm_rf/cache-linux-precise-lkjdhfsod8fu4tc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-2.2.5--gemfile-Gemfile.tgz</Key>
          <LastModified>2009-10-12T17:50:30.000Z</LastModified>
          <ETag>&quot;hgb9dede5f27731c9771645a39863328&quot;</ETag>
          <Size>20308738</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
      </Contents>
      <Contents>
         <Key>#{repo.github_id}/master/cache-linux-precise-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz</Key>
           <LastModified>2009-10-12T17:50:30.000Z</LastModified>
           <ETag>&quot;1b2cf535f27731c974343645a3985328&quot;</ETag>
           <Size>64994</Size>
           <StorageClass>STANDARD_IA</StorageClass>
           <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
      </Contents>
    </ListBucketResult>"
  }



  let(:xml_content_single_repo) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>#{s3_bucket_name}</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
      <Contents>
          <Key>#{repo.github_id}/ha-bug-rm_rf/cache-linux-precise-lkjdhfsod8fu4tc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-2.2.5--gemfile-Gemfile.tgz</Key>
          <LastModified>2009-10-12T17:50:30.000Z</LastModified>
          <ETag>&quot;hgb9dede5f27731c9771645a39863328&quot;</ETag>
          <Size>20308738</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
      </Contents>
    </ListBucketResult>"
  }

  let(:empty_xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>#{s3_bucket_name}</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
    </ListBucketResult>"
  }

  let(:gcs_json_bucket_response) {
    %q{
      {"kind": "storage#bucket",
       "selfLink":  "https://www.googleapis.com/storage/v1/b/travis-cache-staging-org-gce",
        "name": "travis-cache-production-org-gce",
        "id": "travis-cache-staging-org-gce/25736446"
      }
    }
  }
  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    repo.default_branch.save!
    repo.owner.permissions.create(repository_id: repo.id, push: true)

    stub_request(:post, "https://oauth2.googleapis.com/token").
      to_return(:status => 200, :body => "{}", :headers => {"Content-Type" => "application/json"})
    stub_request(:get,%r((.+))).with(
      headers: { 'Metadata-Flavor'=>'Google', 'User-Agent'=>'Ruby'}
    ).to_return(status: 200, body: "", headers: {})

    stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce").
      to_return(:status => 200, :body => gcs_json_bucket_response, :headers => {"Content-Type" => "application/json"})

    stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce/o").
      to_return(:status => 200, :body => gcs_json_response, :headers => {"Content-Type" => "application/json"})

    stub_request(:get, "https://travis-cache-staging-org.s3.us-east-2.amazonaws.com/?encoding-type=url").
      to_return(:status => 200, :body => xml_content_single_repo, :headers => {})
    stub_request(:get, "https://travis-cache-staging-org.s3.us-east-2.amazonaws.com/1/ha-bug-rm_rf/cache-linux-precise-lkjdhfsod8fu4tc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-2.2.5--gemfile-Gemfile.tgz").
      to_return(:status => 200, :body => xml_content_single_repo, :headers => {})
   stub_request(:get, "https://travis-cache-staging-org.s3.us-east-2.amazonaws.com/1/master/cache-linux-precise-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz").
      to_return(:status => 200, :body => xml_content_single_repo, :headers => {})
  end

  around(:each) do |example|
    Travis.config.cache_options.s3 = { access_key_id: 'key', secret_access_key: 'secret', bucket_name: s3_bucket_name }
    Travis.config.cache_options.gcs = { bucket_name: 'travis-cache-production-org-gce',
    json_key:
      JSON.generate({
        "type" => "service_account",
        "project_id" => "123",
        "private_key_id" => "123456",
        "private_key" => TEST_PRIVATE_KEY,
        "client_email" => "travis-cache-org-api-production",
        "client_id" => "1234",
        "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
        "token_uri" => "https://accounts.google.com/oauth2/v4/token",
        "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url" => "travis-cache-org-api-production"
      }),
    project_id: 'foo-bar-99515' }
    Travis.config.cache_options.gcs = { bucket_name: 'travis-cache-production-org-gce',
      json_key:
        {
          "type" => "service_account",
          "project_id" => "123",
          "private_key_id" => "123456",
          "private_key" => TEST_PRIVATE_KEY,
          "client_email" => "travis-cache-org-api-production",
          "client_id" => "1234",
          "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
          "token_uri" => "https://accounts.google.com/oauth2/v4/token",
          "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url" => "travis-cache-org-api-production"
        },
      project_id: 'foo-bar-99515' }
    example.run
    Travis.config.cache_options = {}
  end

  describe "existing cache on s3 and gcs" do
    before     do
      stub_request(:get, "https://#{s3_bucket_name}.s3.us-east-2.amazonaws.com/?encoding-type=url&prefix=1/").
        to_return(:status => 200, :body => xml_content, :headers => {})

      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce/o?prefix=1/").
        to_return(:status => 200, :body => gcs_json_response, :headers => {"Content-Type" => "application/json"})

    end
    before     { get("/v3/repo/#{repo.id}/caches", {}, headers) }
    example    { expect(last_response).to be_ok }
    example    do
      expect(JSON.load(body)).to be == {
        "@type"=>"caches",
        "@href"=>"/v3/repo/#{repo.id}/caches",
        "@representation"=>"standard",
        "caches"=> result
      }
    end
  end

  describe "filter by branch s3" do
    before     do
      stub_request(:get, "https://#{s3_bucket_name}.s3.us-east-2.amazonaws.com/?encoding-type=url&prefix=1/ha-bug-rm_rf/").
        to_return(:status => 200, :body => xml_content_single_repo, :headers => {})

      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce/o?prefix=1/ha-bug-rm_rf/").
        to_return(:status => 200, :body => empty_gcs_content, :headers => {"Content-Type" => "application/json"})
    end

    example do
      get("/v3/repo/#{repo.id}/caches", { branch: result[0]["branch"] }, headers)
      expect(JSON.load(body)).to be == {
        "@type"=>"caches",
        "@href"=>"/v3/repo/1/caches?branch=#{result[0]["branch"]}",
        "@representation"=>"standard",
        "caches"=> [result[0]]
      }
    end
  end

  describe "filter by match on gcs" do
    before do
      stub_request(:get, "https://#{s3_bucket_name}.s3.us-east-2.amazonaws.com/?encoding-type=url&prefix=1/").
        to_return(:status => 200, :body => empty_xml_content, :headers => {})

      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce/o?prefix=1/").
        to_return(:status => 200, :body => gcs_json_response, :headers => {"Content-Type" => "application/json"})
    end

    example do
      get("/v3/repo/#{repo.id}/caches?match=osx", {}, headers)
      expect(JSON.load(body)).to be == {
        "@type"=>"caches",
        "@href"=>"/v3/repo/1/caches?match=osx",
        "@representation"=>"standard",
        "caches"=> [result[2]]
      }
    end
  end

  context "without push permission" do

    let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
    it "raises Travis::AuthorizationDenied" do
      repo.owner.permissions.last.update(push: false)

      get("/v3/repo/#{repo.id}/caches?match=osx", {}, headers)

      expect(JSON.load(body)).to include({
        "@type" => "error",
        "error_type" => "insufficient_access",
        "error_message" => "operation requires cache_view access to repository",
      })
      expect(last_response.status).to eq 403
    end
  end
end
