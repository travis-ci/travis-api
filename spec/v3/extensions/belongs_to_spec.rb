require 'spec_helper'

describe Travis::API::V3::Extensions::BelongsTo do
  describe 'reading polymorphic relation' do
    subject(:repo) { Travis::API::V3::Models::Repository.first }
    example { expect(repo.owner).to be_a(Travis::API::V3::Models::User) }
  end

  describe 'writing polymorphic relation' do
    let(:repo) { Travis::API::V3::Models::Repository.create(owner: user) }
    let(:user) { Travis::API::V3::Models::User.create }
    after      { repo.destroy; user.destroy }

    example { expect(repo.owner).to be_a(Travis::API::V3::Models::User) }
    example { expect(Travis::API::V3::Models::Repository.find(repo.id).owner).to be_a(Travis::API::V3::Models::User)  }
    example { expect(user.repositories).to include(repo)                }
  end
end
