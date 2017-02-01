RSpec.shared_examples 'not authenticated' do
  example { expect(last_response.status).to eq(403) }
  example do
    expect(JSON.load(body)).to eq(
      '@type' => 'error',
      'error_type' => 'login_required',
      'error_message' => 'login required'
    )
  end
end

RSpec.shared_examples 'insufficient access to repo' do |permission|
  example { expect(last_response.status).to eq(403) }
  example do
    expect(JSON.load(body)).to eq(
      '@type' => 'error',
      'error_type' => 'insufficient_access',
      'error_message' => "operation requires #{permission} access to repository",
      'permission' => permission,
      'resource_type' => 'repository',
      'repository' => {
        '@type' => 'repository',
        '@href' => "/v3/repo/#{repo.id}",
        '@representation' => 'minimal',
        'id' => repo.id,
        'name' => repo.name,
        'slug' => repo.slug
      }
    )
  end
end

RSpec.shared_examples 'wrong params' do
  example { expect(last_response.status).to eq 400 }
  example do
    expect(JSON.parse(last_response.body)).to eq(
      '@type' => 'error',
      'error_message' => 'wrong parameters',
      'error_type' => 'wrong_params'
    )
  end
end

RSpec.shared_examples 'missing repo' do
  example { expect(last_response.status).to eq(404) }
  example do
    expect(JSON.load(body)).to eq(
      '@type' => 'error',
      'error_message' => 'repository not found (or insufficient access)',
      'error_type' => 'not_found',
      'resource_type' => 'repository'
    )
  end
end

RSpec.shared_examples 'missing env_var' do
  example { expect(last_response.status).to eq 404 }
  example do
    expect(JSON.load(body)).to eq(
      '@type' => 'error',
      'error_message' => 'env_var not found (or insufficient access)',
      'error_type' => 'not_found',
      'resource_type' => 'env_var'
    )
  end
end
