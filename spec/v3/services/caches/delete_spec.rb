describe Travis::API::V3::Services::Caches::Delete, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:jobs)  { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:s3_bucket_name) { "travis-cache-staging-org" }
  let(:result) { [
    {
      "@type"=>"cache",
      "@representation"=>"standard",
      "repository_id"=>1,
      "size"=>20308738,
      "branch"=>"ha-bug-rm_rf",
      "last_modified"=>"2009-10-12T17:50:30Z",
      "slug"=>"cache-linux-precise-lkjdhfsod8fu4tc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-2.2.5--gemfile-Gemfile.tgz",
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
      "slug"=>"cache-linux-precise-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855--rvm-default--gemfile-Gemfile.tgz",
      "repo"=>{
        "@type"=>"repository",
        "@href"=>"/v3/repo/#{repo.id}",
        "@representation"=>"minimal",
        "id"=>repo.id,
        "name"=>repo.name,
        "slug"=>repo.slug
        }
      }
    ]
  }
  let(:xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>bucket</Name>
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
    <Name>bucket</Name>
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
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
    </ListBucketResult>"
  }
  before { repo.default_branch.save! }

  describe "delete all on s3" do
    before     do
      stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
        to_return(:status => 200, :body => xml_content, :headers => {})
      stub_request(:get, "https://travis-cache-staging-org.s3.amazonaws.com/?prefix=#{repo.id}/").
        to_return(:status => 200, :body => xml_content, :headers => {})
      stub_request(:delete, "https://bucket.s3.amazonaws.com/#{repo.id}/#{result[0]["branch"]}/#{result[0]["slug"]}").
        to_return(:status => 200, :body => xml_content, :headers => {})
      Fog.mock!
      Travis.config.cache_options.gcs = { json_key: 'key', google_project: 'pj', bucket_name: 'bucket' }
      storage = Fog::Storage::Google.new({
        google_json_key_string: 'key',
        google_project: 'pj'
      })

      ## FIXME:
      bucket = storage.directories.create(key: "#{repo.id}/branch")
      file = bucket.files.create(
        key: "some file",
        body: "something to test"
      )
    end
    after { Fog::Mock.reset }

    before     { delete("/v3/repo/#{repo.id}/caches") }
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

  describe "delete for branch" do
    before     do
      stub_request(:get, "https://#{s3_bucket_name}.s3.amazonaws.com/?prefix=#{repo.id}/#{result[0]["branch"]}").
         to_return(:status => 200, :body => xml_content_single_repo, :headers => {})
    end

    example do
      delete("/v3/repo/#{repo.id}/caches", { branch: result[0]["branch"] } )
      expect(JSON.load(body)).to be == {
        "@type"=>"caches",
        "@href"=>"/v3/repo/1/caches?branch=#{result[0]["branch"]}",
        "@representation"=>"standard",
        "caches"=> [result[0]]
      }
    end
  end

  describe "delete for match" do
    before     do
      stub_request(:get, "https://#{s3_bucket_name}.s3.amazonaws.com/?prefix=#{repo.id}/#{result[0]["branch"]}").
         to_return(:status => 200, :body => xml_content, :headers => {})
    end

    example do
      delete("/v3/repo/#{repo.id}/caches", { branch: result[0]["branch"], match: 'dhfsod8fu4' } )
      expect(JSON.load(body)).to be == {
        "@type"=>"caches",
        "@href"=>"/v3/repo/1/caches?branch=#{result[0]["branch"]}&match=dhfsod8fu4",
        "@representation"=>"standard",
        "caches"=> [result[0]]
      }
    end
  end

  describe "delete all on gcs" do
    before     do
      stub_request(:get, "https://#{s3_bucket_name}.s3.amazonaws.com/?prefix=#{repo.id}/").
         to_return(:status => 200, :body => empty_xml_content, :headers => {})
      stub_request(:post, "https://accounts.google.com/o/oauth2/token").
         to_return(:status => 200, :body => {authorization: 'skdjfhdkfh'}.to_json, :headers => {content_type: 'application/json'})

      stub_request(:get, "https://www.googleapis.com/storage/v1/b/travis-cache-staging-org-gce/?prefix=#{repo.id}/").
         to_return(:status => 200, :body => xml_content, :headers => {})

    end
    before     { delete("/v3/repo/#{repo.id}/caches") }
    skip    do
      expect(JSON.load(body)).to be == {
        "@type"=>"caches",
        "@href"=>"/v3/repo/#{repo.id}/caches",
        "@representation"=>"standard",
        "caches"=> result
      }
    end
  end
end
