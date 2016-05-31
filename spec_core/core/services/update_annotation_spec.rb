require 'spec_helper'

describe Travis::Services::UpdateAnnotation do
  include Support::ActiveRecord

  let(:annotation_provider) { Factory(:annotation_provider) }
  let(:job) { Factory(:test) }
  let(:service) { described_class.new(params) }
  let(:repository) { Factory(:repository) }

  attr_reader :params

  context 'when annotation is enabled' do
    before :each do
      job.stubs(:repository).returns(repository)
      Travis::Features.stubs(:active?).returns(true)
    end

    it 'creates the annotation if it doesn\'t exist already' do
      @params = {
        username: annotation_provider.api_username,
        key: annotation_provider.api_key,
        job_id: job.id,
        description: 'Foo bar baz',
      }

      expect {
        @annotation = service.run
      }.to change(Annotation, :count).by(1)
      @annotation.description.should eq(params[:description])
    end

    it 'updates an existing annotation if one exists' do
      @params = {
        username: annotation_provider.api_username,
        key: annotation_provider.api_key,
        job_id: job.id,
        description: 'Foo bar baz',
      }

      annotation = Factory(:annotation, annotation_provider: annotation_provider, job: job)
      service.run.id.should eq(annotation.id)
    end
  end

  context 'when annotation is disabled' do
    before :each do
      job.stubs(:repository).returns(repository)
      Travis::Features.stubs(:active?).returns(false)
    end

    it 'returns nil' do
      @params = {
        username: annotation_provider.api_username,
        key: annotation_provider.api_key,
        job_id: job.id,
        description: 'Foo bar baz',
      }

      service.run.should be_nil
    end
  end

  it 'returns nil when given invalid provider credentials' do
    @params = {
      username: 'some-invalid-provider',
      key: 'some-invalid-key',
      job_id: job.id,
      description: 'Foo bar baz',
    }

    service.run.should be_nil
  end
end
