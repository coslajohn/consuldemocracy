class Admin::SegmentsController < Admin::BaseController
  load_and_authorize_resource

  def index
    @segments = @segments.order(:name)
  end

  def new
  end

  def create
    if @segment.save
      redirect_to admin_segments_path, notice: t("admin.segments.create.notice")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @segment.update(segment_params)
      redirect_to admin_segments_path, notice: t("admin.segments.update.notice")
    else
      render :edit
    end
  end

  def destroy
    @segment.destroy
    redirect_to admin_segments_path, notice: t("admin.segments.destroy.notice")
  end

  private

  def segment_params
    params.require(:segment).permit(:name, :description)
  end
end
