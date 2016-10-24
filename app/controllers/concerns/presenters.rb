module Presenters
  def present(model)
    "#{model.class}Presenter".constantize.new(model, self)
  end
end