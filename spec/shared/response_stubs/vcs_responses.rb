module ResponseStubs
  shared_context 'vcs_responses' do
    let(:vcs_response) do
      [
        {
          'type' => 'Repository',
          'id' => repo.id,
          'name' => 'travis',
          'active' => true,
          'events' => %w[push pull_request],
          'config' => {
            'content_type' => 'json',
            'insecure_ssl' => '0',
            'url' => 'https://example.com/',
            'domain' => 'notify.fake.travis-ci.com'
          },
          'updated_at' => '2019-06-16T18:11:10.000Z',
          'created_at' => '2019-06-16T18:11:10.000Z',
          'url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'test_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'ping_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'last_response' => { 'code' => nil, 'status' => 'unused', 'message' => nil }
        }
      ].to_json
    end

    let(:vcs_not_active) do
      [
        {
          'type' => 'Repository',
          'id' => repo.id,
          'name' => 'travis',
          'active' => false,
          'events' => %w[push pull_request],
          'config' => {
            'content_type' => 'json',
            'insecure_ssl' => '0',
            'url' => 'https://example.com/',
            'domain' => 'notify.fake.travis-ci.com'
          },
          'updated_at' => '2019-06-16T18:11:10.000Z',
          'created_at' => '2019-06-16T18:11:10.000Z',
          'url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'test_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'ping_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'last_response' => { 'code' => nil, 'status' => 'unused', 'message' => nil }
        }
      ].to_json
    end

    let(:vcs_pr_missing) do
      [
        {
          'type' => 'Repository',
          'id' => repo.id,
          'name' => 'travis',
          'active' => true,
          'events' => %w[push],
          'config' => {
            'content_type' => 'json',
            'insecure_ssl' => '0',
            'url' => 'https://example.com/',
            'domain' => 'notify.fake.travis-ci.com'
          },
          'updated_at' => '2019-06-16T18:11:10.000Z',
          'created_at' => '2019-06-16T18:11:10.000Z',
          'url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'test_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'ping_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'last_response' => { 'code' => nil, 'status' => 'unused', 'message' => nil }
        }
      ].to_json
    end

    let(:vcs_push_missing) do
      [
        {
          'type' => 'Repository',
          'id' => repo.id,
          'name' => 'travis',
          'active' => true,
          'events' => %w[pull_request],
          'config' => {
            'content_type' => 'json',
            'insecure_ssl' => '0',
            'url' => 'https://example.com/',
            'domain' => 'notify.fake.travis-ci.com'
          },
          'updated_at' => '2019-06-16T18:11:10.000Z',
          'created_at' => '2019-06-16T18:11:10.000Z',
          'url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'test_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'ping_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'last_response' => { 'code' => nil, 'status' => 'unused', 'message' => nil }
        }
      ].to_json
    end

    let(:vcs_different_domain) do
      [
        {
          'type' => 'Repository',
          'id' => repo.id,
          'name' => 'travis',
          'active' => true,
          'events' => %w[push pull_request],
          'config' => {
            'content_type' => 'json',
            'insecure_ssl' => '0',
            'url' => 'https://example.com/',
            'domain' => 'notify.fake2.travis-ci.com'
          },
          'updated_at' => '2019-06-16T18:11:10.000Z',
          'created_at' => '2019-06-16T18:11:10.000Z',
          'url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'test_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'ping_url' => "https://example.com/repos/#{repo.slug}/hooks/1",
          'last_response' => { 'code' => nil, 'status' => 'unused', 'message' => nil }
        }
      ].to_json
    end
  end
end
