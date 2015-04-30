require 'spec_helper'

describe Travis::API::V3::Renderer::AvatarURL do
  let(:object) { Object.new }
  subject { Travis::API::V3::Renderer::AvatarURL.avatar_url(object) }

  describe 'without any useful information' do
    it { should be_nil }
  end

  describe 'with valid avatar_url' do
    let(:object) { stub('input', avatar_url: "http://foo") }
    it { should be == "http://foo" }
  end

  describe 'with valid avatar_url' do
    let(:object) { stub('input', gravatar_url: "http://foo") }
    it { should be == "http://foo" }
  end

  describe 'with valid gravatar_id' do
    let(:object) { stub('input', gravatar_id: "foo") }
    it { should be == "https://0.gravatar.com/avatar/foo" }
  end

  describe 'with valid avatar_url and gravatar_id' do
    let(:object) { stub('input', avatar_url: "http://foo", gravatar_id: "https://0.gravatar.com/avatar/foo") }
    it { should be == "http://foo" }
  end

  describe 'with missing avatar_url and valid gravatar_id' do
    let(:object) { stub('input', avatar_url: nil, gravatar_id: "foo") }
    it { should be == "https://0.gravatar.com/avatar/foo" }
  end

  describe 'with email' do
    let(:object) { stub('input', email: "foo") }
    it { should be == "https://0.gravatar.com/avatar/acbd18db4cc2f85cedef654fccc4a4d8" }
  end

  describe 'with missing email' do
    let(:object) { stub('input', email: nil) }
    it { should be_nil }
  end
end