module Travis
  module Services
    class UpdateAnnotation < Base
      register :update_annotation

      def run
        if annotations_enabled? && annotation_provider
          cached_annotation = annotation
          cached_annotation.update_attributes!(attributes)

          cached_annotation
        end
      end

      private

      def annotations_enabled?
        job  = Job.find(params[:job_id])
        repo = job.repository
        Travis::Features.enabled_for_all?(:annotations) || Travis::Features.active?(:annotations, repo)
      end

      def annotation
        annotation_provider.annotation_for_job(params[:job_id])
      end

      def annotation_provider
        @annotation_provider ||= AnnotationProvider.authenticate_provider(params[:username], params[:key])
      end

      def attributes
        params.slice(:description, :status, :url)
      end
    end
  end
end
