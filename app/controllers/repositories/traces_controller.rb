module Repositories
  class TracesController < ApplicationController
    prepend_before_action :check_build_trace, only: %I[list enable disable]
    before_action :fetch_repository, only: %I[list enable disable]

    def list
      redirect_to build_list_url
    end

    def enable
      Travis::DataStores.redis.sadd('trace.rollout.repos', @repository.slug)
      flash[:notice] = 'Enabled build tracing'
      redirect_to @repository
    end

    def disable
      Travis::DataStores.redis.srem('trace.rollout.repos', @repository.slug)
      flash[:notice] = 'Disable build tracing'
      redirect_to @repository
    end

    private

    def fetch_repository
      @repository = Repository.find_by(id: params[:repository_id])

      unless @repository
        flash[:error] = "There is no repository associated with ID #{params[:repository_id]}."
        redirect_to not_found_path
      end
    end

    def build_list_url
      url = 'https://console.cloud.google.com/traces/traces'
      url + '?' + URI.encode_www_form(
        project: ENV['BUILD_TRACE_GOOGLE_PROJECT'],
        q: "+app:build +repo:#{@repository.slug}"
      )
    end

    def check_build_trace
      raise 'no build trace project set' unless ENV['BUILD_TRACE_GOOGLE_PROJECT']
    end
  end
end
