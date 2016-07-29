module Travis
  class RepositoryNotFoundError < StandardError
    def initialize(params)
      details = ''

      if id = params[:repository_id] || params[:id]
        details = "with id=#{params[:repository_id] || params[:id]} "
      elsif params[:github_id]
        details = "with github_id=#{params[:github_id]} "
      elsif params.key?(:slug)
        details = "with slug=#{params[:slug]} "
      elsif params.key?(:name) && params.key?(:owner_name)
        details = "with slug=#{params[:name]}/#{params[:owner_name]} "
      end


      super("Repository #{details}could not be found")
    end
  end
end
