module Travis
  module Services
    class FindAnnotations < Base
      register :find_annotations

      def run
        if params[:ids]
          scope(:annotation).where(id: params[:ids])
        elsif params[:job_id]
          scope(:annotation).where(job_id: params[:job_id])
        else
          []
        end
      end
    end
  end
end
