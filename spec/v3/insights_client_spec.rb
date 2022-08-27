describe Travis::API::V3::InsightsClient, insights_spec_helper: true do
  let(:insights) { described_class.new(user_id) }
  let(:user_id) { rand(999) }
  let(:insights_url) { 'https://new-insights.travis-ci.com/' }
  let(:auth_key) { 'supersecret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = auth_key
  end

  describe '#user_notifications' do
    let(:filter) { nil }
    let(:page) { '1' }
    let(:active) { '0' }
    let(:sort_by) { 'probe_severity' }
    let(:sort_direction) { 'desc' }

    subject { insights.user_notifications(filter, page, active, sort_by, sort_direction) }

    it 'requests user notifications with specified query' do
      stub_insights_request(:get, '/user_notifications', query: "page=#{page}&active=#{active}&order=#{sort_by}&order_dir=#{sort_direction}", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(insights_notifications_response))
      expect(subject).to be_a(Travis::API::V3::Models::InsightsCollection)
      expect(subject.map { |e| e }.first).to be_a(Travis::API::V3::Models::InsightsNotification)
      expect(subject.map { |e| e }.size).to eq(insights_notifications_response['data'].size)
      expect(subject.count).to eq(insights_notifications_response['total_count'])
    end
  end

  describe '#toggle_snooze_user_notifications' do
    let(:notification_ids) { [123, 345] }
    subject { insights.toggle_snooze_user_notifications(notification_ids) }

    it 'requests the toggle of user notifications' do
      stubbed_request = stub_insights_request(:put, '/user_notifications/toggle_snooze', auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(snooze_ids: notification_ids))
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#user_plugins' do
    let(:filter) { nil }
    let(:page) { '1' }
    let(:active) { '1' }
    let(:sort_by) { 'name' }
    let(:sort_direction) { 'desc' }

    subject { insights.user_plugins(filter, page, active, sort_by, sort_direction) }

    it 'requests user plugins with specified query' do
      stub_insights_request(:get, '/user_plugins', query: "page=#{page}&active=#{active}&order=#{sort_by}&order_dir=#{sort_direction}", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(insights_plugins_response))
      expect(subject).to be_a(Travis::API::V3::Models::InsightsCollection)
      expect(subject.map { |e| e }.first).to be_a(Travis::API::V3::Models::InsightsPlugin)
      expect(subject.map { |e| e }.size).to eq(insights_plugins_response['data'].size)
      expect(subject.count).to eq(insights_plugins_response['total_count'])
    end
  end

  describe '#create_plugin' do
    let(:name) { 'Test Plugin' }
    let(:plugin_data) { { 'name' => name } }
    subject { insights.create_plugin(plugin_data) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_insights_request(:post, '/user_plugins', auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(user_plugin: plugin_data))
        .to_return(status: 201, body: JSON.dump(insights_create_plugin_response('name' => name)))

      expect(subject).to be_a(Travis::API::V3::Models::InsightsPlugin)
      expect(subject.name).to eq(name)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#toggle_active_plugins' do
    let(:plugin_ids) { [123, 345] }
    subject { insights.toggle_active_plugins(plugin_ids) }

    it 'requests the toggle of plugins' do
      stubbed_request = stub_insights_request(:put, '/user_plugins/toggle_active', auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(toggle_ids: plugin_ids))
        .to_return(status: 200, body: '')

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#delete_many_plugins' do
    let(:plugin_ids) { [123, 345] }
    subject { insights.delete_many_plugins(plugin_ids) }

    it 'requests the delete' do
      stubbed_request = stub_insights_request(:delete, '/user_plugins/delete_many', query: { delete_ids: plugin_ids }.to_query, auth_key: auth_key, user_id: user_id)
        .to_return(status: 200, body: '')

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#run_scan' do
    subject { insights.run_scan }

    it 'requests to run scan' do
      stubbed_request = stub_insights_request(:get, '/user_plugins/run_scan', auth_key: auth_key, user_id: user_id)
        .to_return(status: 200, body: '')

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#generate_key' do
    let(:plugin_name) { 'name' }
    let(:plugin_type) { 'type' }
    subject { insights.generate_key(plugin_name, plugin_type) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_insights_request(:get, '/user_plugins/generate_key', query: { name: plugin_name, plugin_type: plugin_type }.to_query, auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_generate_key_response))

      expect(subject['keys'][0]).to eq('TIDE0C7A9C1D5E')
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#authenticate_key' do
    let(:key_data) { { 'public_id' => 'id', 'private_key' => 'key' } }
    subject { insights.authenticate_key(key_data) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_insights_request(:post, '/user_plugins/authenticate_key', auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(key_data))
        .to_return(status: 201, body: JSON.dump(insights_authenticate_key_response))

      expect(subject['success']).to be_truthy
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#template_plugin_tests' do
    let(:plugin_type) { 'sre' }
    subject { insights.template_plugin_tests(plugin_type) }

    it 'requests the template tests' do
      stubbed_request = stub_insights_request(:get, "/user_plugins/#{plugin_type}/template_plugin_tests", auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_template_plugin_tests_response))

      expect(subject['template_tests']).to eq(insights_template_plugin_tests_response['template_tests'])
      expect(subject['plugin_category']).to eq(insights_template_plugin_tests_response['plugin_category'])
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#get_scan_logs' do
    subject { insights.get_scan_logs(plugin_id, last_id) }

    context 'when last_id is not present' do
      let(:plugin_id) { rand(999) }
      let(:last_id) { nil }

      it 'requests scan logs for specified plugin' do
        stub_insights_request(:get, "/user_plugins/#{plugin_id}/get_scan_logs", auth_key: auth_key, user_id: user_id)
          .to_return(body: JSON.dump(insights_scan_log_response))

        expect(subject['scan_logs']).to eq(insights_scan_log_response['scan_logs'])
      end
    end

    context 'when last_id is present' do
      let(:plugin_id) { rand(999) }
      let(:last_id) { rand(999) }

      it 'requests scan logs for specified plugin' do
        stub_insights_request(:get, "/user_plugins/#{plugin_id}/get_scan_logs", query: "last=#{last_id}&poll=true", auth_key: auth_key, user_id: user_id)
          .to_return(body: JSON.dump(insights_scan_log_response))

        expect(subject['scan_logs']).to eq(insights_scan_log_response['scan_logs'])
      end
    end
  end

  describe '#probes' do
    let(:filter) { nil }
    let(:page) { '1' }
    let(:active) { '1' }
    let(:sort_by) { 'name' }
    let(:sort_direction) { 'desc' }

    subject { insights.probes(filter, page, active, sort_by, sort_direction) }

    it 'requests probes with specified query' do
      stub_insights_request(:get, '/probes', query: "page=#{page}&active=#{active}&order=#{sort_by}&order_dir=#{sort_direction}", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(insights_probes_response))
      expect(subject).to be_a(Travis::API::V3::Models::InsightsCollection)
      expect(subject.map { |e| e }.first).to be_a(Travis::API::V3::Models::InsightsProbe)
      expect(subject.map { |e| e }.size).to eq(insights_probes_response['data'].size)
      expect(subject.count).to eq(insights_probes_response['total_count'])
    end
  end

  describe '#create_probe' do
    let(:notification) { 'Test Probe' }
    let(:probe_data) { { 'notification' => notification } }
    subject { insights.create_probe(probe_data) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_insights_request(:post, '/probes', auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(test_template: probe_data))
        .to_return(status: 201, body: JSON.dump(insights_create_probe_response('notification' => notification)))

      expect(subject).to be_a(Travis::API::V3::Models::InsightsProbe)
      expect(subject.notification).to eq(notification)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_probe' do
    let(:probe_id) { 444 }
    let(:notification) { 'Test Probe' }
    let(:probe_data) { { 'probe_id' => probe_id, 'notification' => notification } }
    subject { insights.update_probe(probe_data) }

    it 'requests the update' do
      stubbed_request = stub_insights_request(:patch, "/probes/#{probe_id}", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(probe_data))
        .to_return(status: 201, body: JSON.dump(insights_create_probe_response('id' => probe_id, 'notification' => notification)))

      expect(subject).to be_a(Travis::API::V3::Models::InsightsProbe)
      expect(subject.id).to eq(probe_id)
      expect(subject.notification).to eq(notification)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#get_probe' do
    let(:probe_id) { 444 }
    let(:probe_data) { { 'probe_id' => probe_id } }
    subject { insights.get_probe(probe_data) }

    it 'requests the probe returns the representation' do
      stubbed_request = stub_insights_request(:get, "/probes/#{probe_id}/template_test", query: "probe_id=#{probe_id}", auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_create_probe_response('id' => probe_id)))

      expect(subject).to be_a(Travis::API::V3::Models::InsightsProbe)
      expect(subject.id).to eq(probe_id)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#toggle_active_probes' do
    let(:probe_ids) { [123, 345] }
    subject { insights.toggle_active_probes(probe_ids) }

    it 'requests the toggle of probes' do
      stubbed_request = stub_insights_request(:put, '/probes/toggle_active', auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(toggle_ids: probe_ids))
        .to_return(status: 200, body: '')

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#delete_many_probes' do
    let(:probe_ids) { [123, 345] }
    subject { insights.delete_many_probes(probe_ids) }

    it 'requests the delete' do
      stubbed_request = stub_insights_request(:delete, '/probes/delete_many', query: { delete_ids: probe_ids }.to_query, auth_key: auth_key, user_id: user_id)
        .to_return(status: 200, body: '')

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#sandbox_plugins' do
    let(:plugin_type) { 'sre' }
    subject { insights.sandbox_plugins(plugin_type) }

    it 'requests the sandbox plugins and returns the representation' do
      stubbed_request = stub_insights_request(:post, '/sandbox/plugins', auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_sandbox_plugins_response))

      expect(subject['name']).to eq(insights_sandbox_plugins_response['name'])
      expect(subject['data']).to eq(insights_sandbox_plugins_response['data'])
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#sandbox_plugin_data' do
    let(:plugin_id) { 333 }
    subject { insights.sandbox_plugin_data(plugin_id) }

    it 'requests the plugin sandbox data and returns the representation' do
      stubbed_request = stub_insights_request(:post, '/sandbox/plugin_data', auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: insights_sandbox_plugin_data_response)

      expect(subject).to eq(JSON.parse(insights_sandbox_plugin_data_response))
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#sandbox_run_query' do
    let(:plugin_id) { 333 }
    let(:query) { 'assert count($.Plugins) > 4' }
    subject { insights.sandbox_run_query(plugin_id, query) }

    it 'requests the result of query and returns the representation' do
      stubbed_request = stub_insights_request(:post, '/sandbox/run_query', auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_sandbox_query_response))

      expect(subject['positive_results']).to eq(insights_sandbox_query_response['positive_results'])
      expect(subject['negative_results']).to eq(insights_sandbox_query_response['negative_results'])
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#public_key' do
    subject { insights.public_key }

    it 'requests the public key' do
      stubbed_request = stub_insights_request(:get, '/api/v1/public_keys/latest.json', auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_public_key_response))

      expect(subject).to be_a(Travis::API::V3::Models::InsightsPublicKey)
      expect(subject.key_hash).to eq(insights_public_key_response['key_hash'])
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#search_tags' do
    subject { insights.search_tags }

    it 'requests available tags' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 201, body: JSON.dump(insights_tags_response))

      expect(subject.first).to be_a(Travis::API::V3::Models::InsightsTag)
      expect(subject.first.name).to eq(insights_tags_response[0]['name'])
      expect(stubbed_request).to have_been_made
    end
  end

  describe 'error handling' do
    subject { insights.search_tags }

    it 'returns true when 202' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 202)

      expect(subject).to be_truthy
      expect(stubbed_request).to have_been_made
    end

    it 'returns true when 204' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 204)

      expect(subject).to be_truthy
      expect(stubbed_request).to have_been_made
    end

    it 'raises error when 400' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 400, body: JSON.dump({error: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::ClientError)
    end

    it 'raises error when 403' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 403, body: JSON.dump({rejection_code: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::InsufficientAccess)
    end

    it 'raises error when 404' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 404, body: JSON.dump({error: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::NotFound)
    end

    it 'raises error when 422' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 422, body: JSON.dump({error: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::UnprocessableEntity)
    end

    it 'raises error when 500' do
      stubbed_request = stub_insights_request(:get, '/tags', auth_key: auth_key, user_id: user_id)
        .to_return(status: 500)

      expect { subject }.to raise_error(Travis::API::V3::ServerError)
    end
  end
end