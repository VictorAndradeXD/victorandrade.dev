class TagsController < ApplicationController
  before_action :set_tag, only: %i[edit update destroy]

  def index = @tags = current_user.tags.order(:name)
  def new   = @tag  = current_user.tags.build
  def edit; end

  def create
    @tag = current_user.tags.build(tag_params)
    return redirect_to tags_path, notice: "Tag criada." if @tag.save

    render :new, status: :unprocessable_entity
  end

  def update
    return redirect_to tags_path, notice: "Tag atualizada." if @tag.update(tag_params)

    render :edit, status: :unprocessable_entity
  end

  def destroy
    @tag.destroy
    redirect_to tags_path, notice: "Tag removida.", status: :see_other
  end

  private
    def set_tag = @tag = current_user.tags.find(params[:id])
    def tag_params = params.expect(tag: [ :name, :color ])
end
