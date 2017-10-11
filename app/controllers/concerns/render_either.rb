module RenderEither
  def render_either(partial, args = {}, view = 'show')
    if request.xhr?
      render args.merge(partial: partial)
    else
      @render_args = args.merge(partial: partial)
      render view
    end
  end
end
