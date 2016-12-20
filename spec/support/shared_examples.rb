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

RSpec.shared_examples 'missing user' do
  example { expect(last_response.status).to eq(404) }
  example do
    expect(JSON.load(body)).to eq(
      '@type' => 'error',
      'error_message' => 'user not found (or insufficient access)',
      'error_type' => 'not_found',
      'resource_type' => 'user'
    )
  end
end

RSpec.shared_examples 'missing beta_feature' do
  example { expect(last_response.status).to eq(404) }
  example do
    expect(JSON.load(body)).to eq(
      '@type' => 'error',
      'error_message' => 'beta_feature not found (or insufficient access)',
      'error_type' => 'not_found',
      "resource_type"=>"beta_feature"
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
